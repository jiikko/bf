module BF
  class TradeWorker
    # 画面から
    def run(target_price)
      BF::MyTrade.trade_from_buy!(target_price)
    end
  end
end
