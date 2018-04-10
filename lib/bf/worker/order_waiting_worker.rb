module BF
  class OrderWaitingWorker < BaseWorker
    def perform(sell_trade_id)
      sell_trade = BF::MyTrade.find_by_sell(sell_trade_id)
      sell_trade.check_sell_trade
    end
  end
end
