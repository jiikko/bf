module BF
  class MyTradeShip < ::ActiveRecord::Base
    belongs_to :buy_trade, class_name: 'BF::MyTrade'
    belongs_to :sell_trade, class_name: 'BF::MyTrade'
  end
end
