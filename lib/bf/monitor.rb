module BF
  class Monitor
    def current_status
      state = BF::Client.get_state
      state.each do |key, value|
        state[key] = state_const[key][value]
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
