module BF
  class SellingTradeWorker < BaseWorker
    def perform(buy_trade_id)
      buy_trade = BF::MyTrade.find(buy_trade_id)
      timeout =
        if buy_trade.params.present?
          buy_trade.params[:timeout]
        else
          nil
        end
      buy_trade.wait_to_sell(timeout: timeout || 15.minutes)
      buy_trade.run_sell_trade! if buy_trade.succeed?
    end
  end
end
