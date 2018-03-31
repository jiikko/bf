require 'spec_helper'

RSpec.describe BF::MyTrade do
  describe '.run_buy_trade!' do
    context "client.buyでエラーが起きた時" do
      it "sell_tradeは作らないこと" do
        allow_any_instance_of(BF::SellingTradeWorker).to receive(:perform)
        allow_any_instance_of(BF::Client).to receive(:buy) { raise }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(buy_trade.error?).to eq(true)
        expect(buy_trade.sell_trade).to eq(nil)
      end
    end
    context '買い注文を出した時' do
      it 'pairのmy_tradeを作成すること' do
        allow_any_instance_of(BF::SellingTradeWorker).to receive(:perform)
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(buy_trade.price).to eq(300)
        expect(buy_trade.buy?).to eq(true)
        # expect(buy_trade.waiting_to_request?).to eq(true)
        expect(buy_trade.requested?).to eq(true)

        expect(buy_trade.sell_trade.price).to eq(700)
        expect(buy_trade.sell_trade.sell?).to eq(true)
        expect(buy_trade.sell_trade.waiting_to_buy?).to eq(true)
      end
    end
  end

  describe "run_sell_trade!" do
    it "キャンセルされたら中止すること" do
    end
  end
end
