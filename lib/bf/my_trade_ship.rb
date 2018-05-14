module BF
  class MyTradeShip < ::ActiveRecord::Base
    belongs_to :buy_trade, class_name: 'BF::MyTrade'
    belongs_to :sell_trade, class_name: 'BF::MyTrade'

    has_one :scalping_task, foreign_key: :trade_ship_id
  end
end
