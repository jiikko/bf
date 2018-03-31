module BF
  class BaseWorker
    def self.perform_async(args)
      new.perform(*args)
    end
  end
end
