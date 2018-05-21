module BF
  class Monitor
    FETCH_DISPARITY_KEY = 'current_disparity'
    FETCH_STATUS_KEY    = 'BF::Monitor.current_status'

    def self.state_const
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

    def self.state_const_with_number
      {}.tap do |hash|
        BF::Monitor.state_const['health'].values.reverse.map(&:itself).each.with_index { |val, i| hash[val] = i }
      end
    end

    # 乖離率を取得できない場合異常値を返す
    def current_disparity_from_datastore
      (Resque.redis.get(FETCH_DISPARITY_KEY) || 999).to_f
    end

    def current_status_from_datastore
      s = Redis.new.get(FETCH_STATUS_KEY)
      if s
        JSON.parse(s)
      end
      # Resque.redis.get 'BF::Monitor.current_status'
    end

    def current_status
      state = BF::Client.new.get_state
      state.each do |key, value|
        state[key] = self.class.state_const[key][value]
      end
      state
    end

    # for cli
    def current_ranges
      price_table = BF::Trade.price_table
      table = price_table.transform_values { |v| BF::RangeStruct.new(*v) }
      [ table.map { |n, struct| "#{n}m: #{struct.to_s}" }.join(' '),
        BF::Trade.price_directions(price_table).join(' '),
       ].join(' ')
    end
  end
end
