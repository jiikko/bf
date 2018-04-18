module BF
  class BaseWorker
    def self.perform(*args)
      new.perform(*args)
    end

    def self.perform_async(*args)
      @queue = :normal
      Resque.enqueue(self, *args)
    end

    def self.on_failure(e, *args)
      case e
      when Resque::DirtyExit
        BF.logger.info "#{self.inspect}(#{args}) をqueueに積み直しました"
        self.perform_async(*args)
      else
        BF.logger.info "#{self.inspect}(#{args}) で想定外の例外を検出しました。何もしていません。"
        BF.logger.info e.message
      end
    end
  end
end
# require './lib/bf/worker/test_worker'
