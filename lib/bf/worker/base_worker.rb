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
      when Interrupt
        BF.logger.info "Ctrl+cを検出しました。#{self.inspect}(#{args}) をqueueに積み直しました"
        self.perform_async(*args)
      else
        BF.logger.info "[#{e.inspect}] #{self.inspect}(#{args}) で想定外の例外を検出しました。何もしていません。"
        BF.logger.error(e.inspect + e.full_message)
      end
    end

    def self.doing?
      !!Resque.workers.detect do |worker|
        worker.job.present? && check_payload?(worker.job['payload'])
      end
    end

    def self.check_payload?(hash)
      /#{self.to_s}/ =~ hash['class']
    end
  end
end
