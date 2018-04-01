module BF
  class OrderWaitingWorker < BaseWorker
    def perform(buy_trade_id)
      buy_trade = BF::MyTrade.find(buy_trade_id)
      buy_trade.check_buy_trade
    end
  end
end
