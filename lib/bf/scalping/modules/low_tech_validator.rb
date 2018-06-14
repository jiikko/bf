module BF
  class Scalping
    module LowTechValidator
      def valid?
        unless base_valid?
          return false
        end

        # 複数エンキューされていると同じタイミングで爆死する可能性があるので、
        # 同時実行できる数を1つに制限する
        # if BF::ScalpingWorker.doing?
        #  return false
        # end

        unless under?
          BF.logger.debug "[#{self.class}] 1で値幅がn000以上あるので中止しました"
          return false
        end

        unless good_price_detection?
          BF.logger.debug '^下上 以外だったので中止しました'
          return false
        end

        if hight_price?
          BF.logger.debug '5~60の高値より上だったので中止しました'
          return false
        end

        unless is_in_low_range?
          BF.logger.debug "[#{self.class}] n分足で高値なので中止しました"
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

      # 突発的な高値更新した時に飛びつかないようにする
      def hight_price?
        min_of_5_60max = BF::Trade.price_table.select { |x, (min, max)| x >= 5 }.map { |x, (min, max)| max }.min
        last_price = BF::Trade.last.price
        min_of_5_60max > last_price
      end

      # 値幅が大きいとこわいので小刻みな時を狙う(試験運用)
      def under?
        # 差分を計算する
        minutes1 = diff_list = @price_table.values.first
        min = minutes1[0]
        max = minutes1[1]
        diff = max - min
        # 200..1000くらい
        (BF::MyTrade.new.request_order_range..1000).include?(diff)
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
