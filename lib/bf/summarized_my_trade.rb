module BF
  class SummarizedMyTrade < ::ActiveRecord::Base
    enum kind: [:manual, :automation]

    def self.summarize!(ago_days: 2.day)
      utc_offset = Time.current.utc_offset / (60 * 60)
      summarized_my_trade_ships = BF::MyTradeShip.succeed.
        group(:time, "is_manual").
        left_joins(:scalping_task).
        where("#{BF::MyTradeShip.table_name}.created_at > ?", (Time.current.beginning_of_day - ago_days)).
        select("DATE_FORMAT(my_trade_ships.created_at + INTERVAL #{utc_offset} hour, '%Y%m%d') time",
               "(CASE WHEN scalping_tasks.id is null THEN true ELSE false end) as is_manual",
               'sum(sell_table.price * sell_table.size) - sum(buy_table.price * buy_table.size) as profit_by_sql',
               "count(*) as my_trade_count")
      summarized_my_trade_ships.each do |summarized_my_trade_ship|
        summarized_my_trade = self.find_or_create_by(summarized_on: summarized_my_trade_ship.time.to_date,
                                                     kind: summarized_my_trade_ship.is_manual.zero? ? :automation : :manual)
        summarized_my_trade.update!(profit: summarized_my_trade_ship.profit_by_sql.to_i, count: summarized_my_trade_ship.my_trade_count)
      end
    end
  end
end
