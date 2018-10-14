module BF
  class MyTradeShip < ::ActiveRecord::Base
    belongs_to :buy_trade, class_name: 'BF::MyTrade'
    belongs_to :sell_trade, class_name: 'BF::MyTrade'

    has_one :scalping_task, foreign_key: :trade_ship_id, dependent: :destroy

    scope :running, ->{
      join_sql = <<-SQL
      inner join #{BF::MyTrade.table_name} sell_table
        on #{BF::MyTradeShip.table_name}.sell_trade_id = sell_table.id
      SQL
      joins(join_sql).where(
        "sell_table.status in (?) and sell_table.kind = ?",
        BF::MyTrade::RUNNING_STATUS_FOR_SELL.map { |x| BF::MyTrade.statuses[x] },
        BF::MyTrade.kinds[:sell],
      )
    }
    scope :succeed, ->{
      join_sql = <<-SQL
      inner join #{BF::MyTrade.table_name} buy_table
        on  #{BF::MyTradeShip.table_name}.buy_trade_id = buy_table.id
      inner join #{BF::MyTrade.table_name} sell_table
        on #{BF::MyTradeShip.table_name}.sell_trade_id = sell_table.id
      SQL
      from("#{self.table_name} use index(primary)").joins(join_sql).where(
        "sell_table.status = :status and buy_table.status = :status",
        status: BF::MyTrade.statuses[:succeed]
      )
    }

    scope :recent, ->(limit: 8){
      my_trade_ships = BF::MyTradeShip.running.includes(:scalping_task, :sell_trade, :buy_trade).to_a
      my_trade_ships.concat(BF::MyTradeShip.limit(limit).order(id: :desc).includes(:scalping_task, :sell_trade, :buy_trade))
      my_trade_ships.sort_by! { |x| - x.id }
      my_trade_ships.uniq
    }

    def self.last_succeed_at
      BF::MyTrade.last_sell_succeed_at
    end

    def running?
      buy_trade.running? || sell_trade.running?
    end

    def canceled?
      buy_trade.canceled? || sell_trade.canceled? || sell_trade.canceled_before_request?
    end

    def profit
     sell = sell_trade.size * sell_trade.price rescue(return(nil))
     buy  = buy_trade.size * buy_trade.price rescue(return(nil))
     sell - buy
    end

    def duration_from_buy_trade_to_succeed
      buy_trade.updated_at - buy_trade.created_at
    end

    def duration_from_sell_trade_to_succeed
      sell_trade.updated_at - buy_trade.updated_at
    end
  end
end
