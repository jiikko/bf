module BF
  class SellingTradeWorker < BaseWorker
    # 買い注文が成約してから売りを発注する
    def perform(buy_trade_id)
      buy_trade = BF::MyTrade.find(buy_trade_id)
      # 買い注文が成約したかを確認する
      begin
        Timeout.timeout(10.minutes) do
          loop do
            if buy_trade.succeed?
              BF.logger.info "買い注文の成約を確認しました。これから売りを発注します。"
            end
            if buy_trade.sell_trade.canceled_before_request? || buy_trade.sell_trade.timeout_before_request?
              return
            end
            sleep(0.5)
          end
        end
      rescue Timeout::Error => e
        buy_trade.sell_trade.timeout_before_request!
        return
      end
      buy_trade.run_sell_trade!
    end
  end
end
