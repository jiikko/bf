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
        expect(buy_trade.sell_trade).to be_a(BF::MyTrade)
        expect(ResqueSpec.queues['normal'].size).to eq(0)
      end
    end
    context '買いの約定待ちがタイムアウトを迎えた時' do
      it '買い売り注文を売り出さずにキャンセルステータスにする' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:created_at) { 16.minutes.ago }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        ResqueSpec.run!('normal')
        expect(buy_trade.reload.timeout_before_request?).to eq(true)
        expect(buy_trade.sell_trade.canceled_before_request?).to eq(true)
      end
    end
    context '買いの約定待ちに 買い注文が canceled? になった時' do
      it '買い売り注文を売り出さずにキャンセルステータスにする' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        # 約定待ちになってほしいのでACTIVEを返す
        allow_any_instance_of(BF::Client).to receive(:get_order).and_return('ACTIVE')
        allow_any_instance_of(BF::MyTrade).to receive(:canceled?) { true }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        ResqueSpec.run!('normal')
        expect(buy_trade.sell_trade.canceled_before_request?).to eq(true)
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
        expect(ResqueSpec.queues['normal'].map { |x| x[:class] }).to eq(["BF::SellingTradeWorker"])
        expect(buy_trade.price).to eq(300)
        expect(buy_trade.buy?).to eq(true)
        expect(buy_trade.requested?).to eq(true)
        expect(buy_trade.sell_trade.price).to eq(700)
        expect(buy_trade.sell_trade.sell?).to eq(true)
        expect(buy_trade.sell_trade.waiting_to_sell?).to eq(true)
      end
      it '買いが約定しないと売りを発注しない' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:check_buy_trade)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(ResqueSpec.queues['normal'].size).to eq(1)
        expect(buy_trade.sell_trade.waiting_to_sell?).to eq(true)
        begin
          Timeout.timeout(1) do
            ResqueSpec.run!('normal')
            expect(true).to eq(false) # 正しくブロッキングされているなら実行しない
          end
        rescue Timeout::Error
        end
      end

      context '買い注文が約定した時' do
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
          expect(ResqueSpec.queues['normal'].map { |x| x[:class] }).to eq([ "BF::SellingTradeWorker"])
          ResqueSpec.run!('normal')
          expect(buy_trade.reload.succeed?).to eq(true)
          expect(buy_trade.sell_trade.succeed?).to eq(true)
          expect(buy_trade.order_id).to_not eq(nil)
          expect(buy_trade.sell_trade.order_id).to_not eq(nil)
        end

        context "client.sellでエラーが起きた時" do
          it 'sell_trade.status が error になること' do
            allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
            allow_any_instance_of(BF::Client).to receive(:sell) { raise('Timeout::Error') }
            allow_any_instance_of(BF::MyTrade).to receive(:trade_status_of_server?).and_return(true)
            buy_trade = BF::MyTrade.new.run_buy_trade!(300)
            ResqueSpec.run!('normal')
            expect(buy_trade.reload.succeed?).to eq(true)
            expect(buy_trade.sell_trade.error?).to eq(true)
          end
        end
      end
    end
  end
end
