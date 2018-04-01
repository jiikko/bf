module BF
  class SellingTradeWorker < BaseWorker
    # 買い注文が成約してから売りを発注する
    def perform(buy_trade_id)
      buy_trade = BF::MyTrade.find(buy_trade_id)
      # 買い注文が成約したかを確認する
      loop do
        if buy_trade.error? || buy_trade.canceled?
          BF.logger.info "買い注文をポーリングしていましたが#{buy_trade.status}だったので中止しました。売り注文を出していません。"
          buy_trade.sell_trade.canceled_before_request!
          return
        end
        if buy_trade.trade_status_of_server? # TODO リアルタイムAPIを検討する
          buy_trade.succeed!
          BF.logger.info "買い注文の成約を確認しました。これから売りを発注します。"
          break
        end
        sleep(0.5)
      end
      buy_trade.run_sell_trade!
    end
  end
end
