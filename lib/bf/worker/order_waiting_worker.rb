module BF
  class OrderWaitingWorker < BaseWorker
    def perform(sell_trade_id)
      sell_trade = BF::MyTrade.find_by_sell(sell_trade_id)
      loop do
        if sell_trade.trade_sccessd?
          sell_trade.succeed!
          BF.logger.info '売りを確認しました。'
          break
        else
          sleep(100)
        end
      end
    end
  end
end
