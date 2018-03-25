module BF
  class Monitor
    class RangeStruct
      attr_accessor :min, :max, :diff
      def initialize(min, max)
        self.diff = max - min
        self.min = min
        self.max = max
      end

      def to_s
        "#{min} ~ #{max} (#{diff})"
      end
    end

    def current_status
      state = BF::Client.get_state
      state.each do |key, value|
        state[key] = state_const[key][value]
      end
      state
    end

    # for cli
    def current_ranges
      chart = ->(x){
        case x
        when 1
          '上'
        when -1
          '下'
        when 0
          '='
        end
      }
      table = {
        1  => BF::Trade.minutely_range,
        5  => BF::Trade.five_minutely_range,
        10 => BF::Trade.ten_minutely_range,
        30 => BF::Trade.half_hourly_range,
        60 => BF::Trade.hourly_range,
      }
      table = table.map { |n, range|
        { n => RangeStruct.new(*range) }
      }
      # ハッシュの配列をハッシュにしている
      table = {}.tap { |h| table.each {|n| h[n.keys.first] = n.values.first } }
      # [1, 3, 5, 2] => [[1, 3], [3, 5], [5, 2]]
      diff_list = table.values
      pairs = diff_list.map(&:diff).map.with_index { |x, i| [diff_list[i], diff_list[i + 1]] }.reject { |x, y| y.nil? }
      [
        table.map { |n, struct|
          [ "#{n}m: #{struct.to_s}",
          ]
        }.join(' '),
        pairs.map { |x, y| chart.call(x.max <=> y.max) },
      ].join(' ')
    end

    private

    def state_const
      { 'health' => {
          'NORMAL' => '取引所は稼動しています。',
          'BUSY' => '取引所に負荷がかかっている状態です。',
          'VERY BUSY' => '取引所の負荷が大きい状態です。',
          'SUPER BUSY' => '負荷が非常に大きい状態です。発注は失敗するか、遅れて処理される可能性があります。',
          'NO ORDER' => '発注が受付できない状態です。',
          'STOP' => '取引所は停止しています。発注は受付されません。',
        },
        'state' => {
          'RUNNING' => '通常稼働中',
          'CLOSED' => '取引停止中',
          'STARTING' => '再起動中',
          'PREOPEN' => '板寄せ中',
          'CIRCUIT BREAK' => 'サーキットブレイク発動中',
          'AWAITING SQ' => 'Lightning Futures の取引終了後 SQ（清算値）の確定前',
          'MATURED' => 'Lightning Futures の満期に到達',
        }
      }
    end
  end
end
