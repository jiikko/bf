module BF
  class TestWorker < BaseWorker
    def perform
      loop do
        BF.logger.info 'wait...'
        sleep 2
      end
    end
  end
end

