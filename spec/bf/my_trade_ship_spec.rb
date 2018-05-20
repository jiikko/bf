require 'spec_helper'

RSpec.describe BF::MyTradeShip do
  context '約定後の時' do
    it 'return true' do
      sell_trade = BF::MyTrade.create!(price: 1, size: 0.001, status: :succeed, kind: :sell)
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.001, status: :succeed, kind: :buy)
      ship = BF::MyTradeShip.create(sell_trade: sell_trade, buy_trade: buy_trade)
      expect(ship.running?).to eq(false)
    end
  end

  context '注文直後の時' do
    it 'return true' do
      sell_trade = BF::MyTrade.create!(price: 1, size: 0.001, status: :waiting_to_sell, kind: :sell)
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.001, status: :requested,       kind: :buy)
      ship = BF::MyTradeShip.create(sell_trade: sell_trade, buy_trade: buy_trade)
      expect(ship.running?).to eq(true)
    end
  end
end
