module BF
  class BaseWorker
    def self.perform(*args)
      new.perform(*args)
    end

    def self.perform_async(*args)
      @queue = :normal
      Resque.enqueue(self, *args)
    end
  end
end
