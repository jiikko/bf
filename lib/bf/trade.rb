module BF
  class Trade < ::ActiveRecord::Base
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

    def self.minutely_range
      from = RANGE_CONST[:minutely].ago
      to = Time.now
      deviation_value_table = {}
      prices = where(kind: :minutely, created_at: (from..to)).pluck(:price)
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
      [result_prices.max, result_prices.min]
    end
  end
end
