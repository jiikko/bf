module BF
  class TradeWorker < BaseWorker
    def perform(target_price)
      puts 'test'
      BF.logger.info 'test'
      # BF::MyTrade.trade_from_buy!(target_price)
    end
  end
end
