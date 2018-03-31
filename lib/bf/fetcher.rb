module BF
  class Fetcher
    def run
      loop do
        BF::Trade.fetch_with_clean
        sleep(2)
      end
    end
  end

  class StatusFetcher
    def run
      loop do
        Redis.new.set 'BF::Monitor.current_status', BF::Monitor.new.current_status.to_json
        # Resque.redis.set 'BF::Monitor.current_status', BF::Monitor.current_status
        sleep(2)
      end
    end
  end
end
