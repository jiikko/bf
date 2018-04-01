require 'spec_helper'

RSpec.describe BF::MyTrade do
  before do
    ResqueSpec.reset!
  end

  describe '.run_buy_trade!' do
    context "client.buyでエラーが起きた時" do
      it "sell_tradeは作らないこと" do
        allow_any_instance_of(BF::SellingTradeWorker).to receive(:perform)
        allow_any_instance_of(BF::Client).to receive(:buy) { raise }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(buy_trade.error?).to eq(true)
        expect(buy_trade.sell_trade).to eq(nil)
        expect(ResqueSpec.queues['normal'].size).to eq(0)
      end
    end
    context '買いの成約待ちに 買い注文が error? || canceled? になった時' do
      it '注文を売り出さずに' do
        # buy_trade.error? || buy_trade.canceled?
      end
    end
    context '買い注文を出した時' do
      context '発注してからキャンセルになったら' do
        it '買い注文と売り注文を取り下げる' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        end
      end
      it 'pairのmy_tradeを作成すること' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:check_buy_trade)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(ResqueSpec.queues['normal'].map { |x| x[:class] }).to match_array([
          "BF::SellingTradeWorker", "BF::OrderWaitingWorker"
        ])
        expect(buy_trade.price).to eq(300)
        expect(buy_trade.buy?).to eq(true)
        expect(buy_trade.requested?).to eq(true)
        expect(buy_trade.sell_trade.price).to eq(700)
        expect(buy_trade.sell_trade.sell?).to eq(true)
        expect(buy_trade.sell_trade.waiting_to_buy?).to eq(true)
      end
      it '買いが成約しないと売りを発注しない' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:check_buy_trade)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(ResqueSpec.queues['normal'].size).to eq(2)
        expect(buy_trade.sell_trade.waiting_to_buy?).to eq(true)
        begin
          Timeout.timeout(1) do
            ResqueSpec.run!('normal')
            expect(true).to eq(false) # 正しくブロッキングされているなら実行しない
          end
        rescue Timeout::Error
        end
      end

      context '買い注文が成約した時' do
        it 'buy_trade.succeed! になること' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          allow_any_instance_of(BF::MyTrade).to receive(:trade_status_of_server?).and_return(true)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
          ResqueSpec.run!('normal')
          expect(buy_trade.reload.succeed?).to eq(true)
        end

        it '売りを発注すること(run_sell_trade!)' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          allow_any_instance_of(BF::Client).to receive(:sell).and_return(1)
          allow_any_instance_of(BF::MyTrade).to receive(:trade_status_of_server?).and_return(true)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
          ResqueSpec.run!('normal')
          expect(buy_trade.reload.succeed?).to eq(true)
          expect(buy_trade.sell_trade.succeed?).to eq(true)
        end

        context "client.sellでエラーが起きた時" do
          it 'sell_trade.status が error になること' do
          end
        end
      end
    end
  end
end
