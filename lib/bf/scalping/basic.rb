module BF
  class Scalping
    class Basic < Base
      def scalp(dry_run=false)
        @price_table = BF::Trade.price_table

        if valid? && !dry_run
          BF.logger.info '注文しましょう！'
          buy_trade = BF::MyTrade.new.run_buy_trade!(BF::Trade.last.price)
          ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
          return true
        end
      end

      private

      def valid?
        unless super
          return false
        end

        unless under_1000?
          BF.logger.debug '1で値幅が1000以上あるので中止しました'
          return false
        end
        unless good_price_detection?
          BF.logger.debug '^下上 以外だったので中止しました'
          /^下上/
          return false
        end

        unless is_in_low_range?
          BF.logger.debug '1分足で高値なので中止しました'
          return false
        end
        return true
      end

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

      # 値幅が大きいとこわいので小刻みな時を狙う(試験運用)
      def under_1000?
        # 差分を計算する
        minutes1 = diff_list = @price_table.values.first
        min = minutes1[0]
        max = minutes1[1]
        diff = max - min
        (400..1000).include?(diff)
      end

      def good_price_detection?
        directions = BF::Trade.price_directions(@price_table).join
        if /^下上/ =~ directions
          return true
        end
      end
    end
  end

end
