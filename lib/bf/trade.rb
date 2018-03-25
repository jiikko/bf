module BF
  class Trade < ::ActiveRecord::Base
    # 性能が出ないならten_minutelyとかサマライズする
    RANGE_CONST = {
      minutely: 1.minute,
      five_minutely: 5.minute,
      ten_minutely: 10.minute,
      half_hourly: 30.minute,
      hourly: 60.minute,
      daily: 1.day,
    }

    enum kind: RANGE_CONST.keys

    def self.fetch
      create!(kind: :minutely, price: BF::Client.get_ticker['ltp'])
    end

    def self.fetch_with_clean
      fetch
      where(kind: :minutely).where('created_at < ?', 1.hour.ago).delete_all
    end

    def self.minutely_range
      calculate_range(RANGE_CONST[:minutely].ago)
    end

    def self.five_minutely_range
      calculate_range(RANGE_CONST[:five_minutely].ago)
    end

    def self.ten_minutely_range
      calculate_range(RANGE_CONST[:ten_minutely].ago)
    end

    def self.half_hourly_range
      calculate_range(RANGE_CONST[:half_hourly].ago)
    end

    private

    def self.calculate_range(from)
      raise('not found arg of from') if from.nil?
      prices = where(kind: :minutely, created_at: (from..Time.now)).pluck(:price)
      deviation_value_table = {}
      return [0, 0] if prices.empty?
      mean = prices.sum / prices.size
      deviations = prices.map { |x| x - mean }
      variance = deviations.map { |d| d * d }.sum / prices.size
      standrad_deviation = Math.sqrt(variance)
      prices.map { |x| [x, x - mean] }.map do |price, deviation|
        key = ((deviation * 10) / standrad_deviation ) + 50
        deviation_value_table[key] = price
      end
      deviation_value_table =
        deviation_value_table.select do |deviation_value, price|
          true if deviation_value < 60 && deviation_value > 30
        end
      result_prices = deviation_value_table.map { |deviation_value, price| price }
      [result_prices.max || 0, result_prices.min || 0].sort
    end
  end
end
