module BF
  class TestWorker < BaseWorker
    def perform
      puts BF::MyTrade.last
    end
  end
end
