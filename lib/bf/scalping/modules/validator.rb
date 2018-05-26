module BF
  class Scalping
    class Modules
      module Validator
        # 5%を超えると赤字
        def over_disparity?
          disparity = BF::Monitor.new.current_disparity_from_datastore
          disparity >= BF::STOP_DISPARITY_LIMIT
        end

        def store_status_ok?
          health_number = BF::Monitor.state_const_with_number[BF::Monitor.new.current_status_from_datastore['health']]
          health_number == 5
        end
      end
    end
  end
end
