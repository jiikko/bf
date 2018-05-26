require 'spec_helper'

RSpec.describe BF::MyTradeShip do
  describe '#profit' do
    it 'return value' do
      buy_trade  = BF::MyTrade.create!(price: 1000, size: 0.01, status: :succeed, kind: :buy)
      sell_trade = BF::MyTrade.create!(price: 1400, size: 0.01, status: :succeed, kind: :sell)
      closed_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade)
      expect(closed_ship.profit).to eq(4)
    end
  end

  describe '.running' do
    it 'return running ship' do
      sell_trade = BF::MyTrade.create!(price: 1, size: 0.001, status: :waiting_to_sell, kind: :sell)
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.001, status: :requested,       kind: :buy)
      running_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade)

      sell_trade = BF::MyTrade.create!(price: 1, size: 0.001, status: :succeed, kind: :sell)
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.001, status: :succeed, kind: :buy)
      closed_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade)

      expect(running_ship.running?).to eq(true)
      expect(BF::MyTradeShip.running.ids).to eq([running_ship.id])
    end
  end

  describe '#running?' do
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
end
