module BF
  class SellingTradeWorker < BaseWorker
    def perform(buy_trade_id)
      buy_trade = BF::MyTrade.find(buy_trade_id)
      buy_trade.wait_to_sell
      buy_trade.run_sell_trade! if buy_trade.succeed?
    end
  end
end
