module BF
  class Daemon
    def run
      method_names = [
        :fetch_trades,
        :fetch_disparity,
        :fetch_status,
        :clean_old_api_call_logs,
      ]
      threads =
        method_names.map do |method_name|
          Thread.start { public_send(method_name) }
        end
      threads.each(&:join)
    end

    def fetch_trades
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

    def fetch_disparity
      loop do
        unless Setting.record.enabled_calc_disparity
          sleep(10)
          next
        end
        begin
          Resque.redis.set(BF::Monitor::FETCH_DISPARITY_KEY, BF::Client.new.get_disparity)
        rescue => e
          BF.logger.error(e.inspect + e.full_message)
        ensure
          sleep(5)
        end
      end
    end

    def fetch_status
      loop do
        begin
          Resque.redis.set(BF::Monitor::FETCH_STATUS_KEY, BF::Monitor.new.current_status.to_json)
        rescue => e
          BF.logger.error(e.inspect + e.full_message)
        ensure
          sleep(5)
        end
      end
    end

    def clean_old_api_call_logs
      loop do
        BF::ApiCallLog.old.delete_all
        sleep(20)
      end
    end
  end
end
