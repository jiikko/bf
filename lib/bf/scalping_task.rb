module BF
  class ScalpingTask < ::ActiveRecord::Base
    belongs_to :trade_ship, class_name: 'BF::MyTradeShip'

    STATUS_TABLE = {
      1 => '紐づくtrade_shipはありませんでした',
      2 => '紐づくbuy_trade, sell_tradeはありませんでした',
      3 => '買うのを待っている',
      4 => '売れるのを待っている',
      5 => '取引は完了しています',
    }
    RUNNING_STATUSES = [3, 4]

    def self.running?
      return true if BF::ScalpingTask.joins(trade_ship: :buy_trade).where(my_trades: { status: BF::MyTrade.statuses.slice(*BF::MyTrade::RUNNING_STATUS_FOR_BUY).values }).exists?
      return true if BF::ScalpingTask.joins(trade_ship: :sell_trade).where(my_trades: { status: BF::MyTrade.statuses.slice(*BF::MyTrade::RUNNING_STATUS_FOR_SELL).values }).exists?
      false
    end

    def status
      if trade_ship_id.nil? || trade_ship.nil?
        return 1
      end
      if trade_ship.buy_trade.nil? || trade_ship.sell_trade.nil?
        return 2
      end
      buy_trade = trade_ship.buy_trade
      BF::MyTrade::RUNNING_STATUS_FOR_BUY.include?(buy_trade.status.to_sym) && (return(3))
      BF::MyTrade::RUNNING_STATUS_FOR_SELL.include?(buy_trade.sell_trade.status.to_sym) && (return(4))
      return 5
    end

    def running?
      RUNNING_STATUSES.include?(status)
    end
  end
end