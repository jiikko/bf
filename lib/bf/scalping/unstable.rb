module BF
  class Scalping
    class Unstable < Base
      include LowTechValidator

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

      # 5分足で一番下にいること
      def is_in_low_range?
        last_price = BF::Trade.last.price
        minutes =
          @price_table.map { |range, (min, max)|
            [last_price - min, last_price - max]
        }.first(2)
        minutes5 = minutes.last
        BF.logger.debug "[5分足] #{minutes5}"
        minutes5[0] <= 0
      end

      # 値幅が大きいとこわいので小刻みな時を狙う(試験運用)
      def under?
        # 差分を計算する
        minutes1 = diff_list = @price_table.values.first
        min = minutes1[0]
        max = minutes1[1]
        diff = max - min
        (400..5000).include?(diff)
      end

      def good_price_detection?
        true
      end
    end
  end
end
