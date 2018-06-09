module BF
  class SummarizedMyTradeWorker < BaseWorker
    def perform
      SummarizedMyTrade.summarize!
    end
  end
end
