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
        expect(ResqueSpec.queues.size).to eq(0)
      end
    end
    context '買いの成約待ちに 買い注文が error? || canceled? になった時' do
      it '注文を売り出さずに' do
        # buy_trade.error? || buy_trade.canceled?
      end
    end
    context '買い注文を出した時' do
      it 'pairのmy_tradeを作成すること' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:check_buy_trade)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)

        expect(BF::SellingTradeWorker).to have_queue_size_of(1)

        expect(buy_trade.price).to eq(300)
        expect(buy_trade.buy?).to eq(true)
        expect(buy_trade.requested?).to eq(true)

        expect(buy_trade.sell_trade.price).to eq(700)
        expect(buy_trade.sell_trade.sell?).to eq(true)
        expect(buy_trade.sell_trade.waiting_to_buy?).to eq(true)
      end

      it '買いが成約するまで待つこと' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        begin
          Timeout.timeout(1) do
            buy_trade = BF::MyTrade.new.run_buy_trade!(300)
            ResqueSpec.run!('normal')
            expect(true).to eq(false) # 正しくブロッキングされているなら実行しない
          end
        rescue Timeout::Error
          # 実行時エラーにならなければいいので何もしない
        end
      end

      context '買い注文が成約した時' do
        it 'buy_trade.succeed! になること' do
        end

        it '売りを発注すること(run_sell_trade!)' do
        end

        context "client.sellでエラーが起きた時" do
          it 'sell_trade.status が error になること' do
          end
        end
      end
    end
  end
end
