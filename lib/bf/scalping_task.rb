module BF
  class ScalpingTask < ::ActiveRecord::Base
    belongs_to :trade_ship, class_name: 'BF::MyTradeShip'

    def self.running?
        BF::ScalpingTask.joins
    end
  end
end
