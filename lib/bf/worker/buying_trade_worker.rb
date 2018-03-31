module BF
  class BuyingTradeWorker < BaseWorker
    def perform(my_trade_id)
      buy_trade = BF::MyTrade.find(my_trade_id)
      # TODO リアルタイムAPIを検討する
      loop do
        break if buy_trade.complate_trade? || buy_trade.canceled?
        sleep(1)
      end
    end
  end
end
