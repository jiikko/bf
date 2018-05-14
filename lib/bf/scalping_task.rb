module BF
  class ScalpingTask < ::ActiveRecord::Base
    belongs_to :trade_ship, class_name: 'BF::MyTradeShip'

    def self.running?
      return true if BF::ScalpingTask.joins(trade_ship: :buy_trade).where(my_trades: { status: BF::MyTrade.statuses.slice(*BF::MyTrade::RUNNING_STATUS_FOR_BUY).values }).exists?
      return true if BF::ScalpingTask.joins(trade_ship: :sell_trade).where(my_trades: { status: BF::MyTrade.statuses.slice(*BF::MyTrade::RUNNING_STATUS_FOR_SELL).values }).exists?
      false
    end
  end
end
