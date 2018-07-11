module BF
  class Fetcher
    def run
      loop do
        begin
          BF::Trade.fetch_with_clean
        rescue => e
          BF.logger.error(e.inspect + e.full_message)
        ensure
          sleep(0.9)
        end
      end
    end
  end

  class DisparityFetcher
    def run
      loop do
        begin
          Resque.redis.set(BF::Monitor::FETCH_DISPARITY_KEY, BF::Client.new.get_disparity)
        rescue => e
          BF.logger.error(e.inspect + e.full_message)
        ensure
          sleep(5)
        end
      end
    end
  end

  class StatusFetcher
    def run
      loop do
        begin
          Redis.new.set BF::Monitor::FETCH_STATUS_KEY, BF::Monitor.new.current_status.to_json
          # Resque.redis.set BF::Monitor::FETCH_STATUS_KEY, BF::Monitor.current_status
        rescue => e
          BF.logger.error(e.inspect + e.full_message)
        ensure
          sleep(5)
        end
      end
    end
  end
end
