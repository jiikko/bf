require 'spec_helper'

RSpec.describe BF::MyTrade do
  describe '.trade_from_buy!' do
    it 'pairのmy_tradeを作成すること' do
      allow_any_instance_of(BF::Client).to receive(:buy).and_return('abc')
      buy_trade = BF::MyTrade.trade_from_buy!(300)
      expect(buy_trade.price).to eq(300)
      expect(buy_trade.sell_trade.price).to eq(700)
    end
  end
end
