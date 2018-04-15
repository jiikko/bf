module BF
  class ScalpingWorker < BaseWorker
    def perform
      scalping = BF::Scalping.new
      loop do
        if scalping.scalp
          break
        end
        sleep(5)
      end
    end
  end
end
