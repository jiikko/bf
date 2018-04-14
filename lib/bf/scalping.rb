module BF
  class Scalping
    def scalp(dry_run=true)
      @price_table = BF::Trade.price_table
      unless store_status_ok?
        BF.logger.info 'サーバに負荷がかかっているので中止しました'
        return false
      end
      unless under_1000?
        BF.logger.info '1で値幅が1000以上あるので中止しました'
        return false
      end
      unless good_price_detection?
        BF.logger.info '^下上 以外だったので中止しました'
        /^下上/
        return false
      end

      unless is_in_low_range?
        BF.logger.info '1分足で高値なので中止しました'
        return false
      end

      BF.logger.info '注文しましょう！'
      unless dry_run
        BF::MyTrade.newrun_buy_trade!(BF::Trade.last.price)
      end
      return true
    end

    private

    def waiting

    # 1分足で一番下にいること
    def is_in_low_range?
      last_price = BF::Trade.last.price
      minutes1 =
        @price_table.map { |range, (min, max)|
          [last_price - min, last_price - max]
      }.first
      BF.logger.debug "[1分足] #{minutes1}"
      minutes1[0] <= 0
    end

    def store_status_ok?
      health_number = BF::Monitor.state_const_with_number[BF::Monitor.new.current_status_from_datastore['health']]
      health_number == 5
    end

    # 値幅が大きいとこわいので小刻みな時を狙う(試験運用)
    def under_1000?
      # 差分を計算する
      minutes1 = diff_list = @price_table.values.first
      min = minutes1[0]
      max = minutes1[1]
      diff = max - min
      diff < 1000
    end

    def good_price_detection?
      directions = BF::Trade.price_directions(@price_table).join
      if /^下上/ =~ directions
        return true
      end
    end
  end
end
