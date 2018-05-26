module BF
  class Scalping
    class Basic < Base
      include LowTechValidator

      def scalp(dry_run=false)
        @price_table = BF::Trade.price_table

        if valid? && !dry_run
          BF.logger.info '注文しましょう！'
          buy_trade = BF::MyTrade.new.run_buy_trade!(BF::Trade.last.price, { timeout: 2.minutes })
          ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
          return true
        end
      end
    end
  end
end
