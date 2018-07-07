class Factory
  class << self
    def create_my_trade_ship(created_at: nil, by: :automation)
      sell_trade = BF::MyTrade.create!(price: 1, size: 0.1, status: :succeed, kind: :sell)
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.1, status: :succeed, kind: :buy)
      running_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade, created_at: created_at)
      case by
      when :automation
        running_ship.create_scalping_task
      end
      running_ship
    end
  end
end
