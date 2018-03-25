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
      where(kind: :minutely,
            created_at: (from..to)).pluck('max(price), min(price)').to_a.first || [0, 0]
    end
  end
end
