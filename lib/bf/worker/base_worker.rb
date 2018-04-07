module BF
  class BaseWorker
    def self.perform(*args)
      new.perform(*args)
    end

    def self.async_perform(*args)
      @queue = :normal
      Resque.enqueue(self, *args)
    end
  end
end
