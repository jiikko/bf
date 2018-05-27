require "bf/scalping/modules/low_tech_validator"

module BF
  class Scalping
    class Base

      private

      def base_valid?
        if over_disparity?
          BF.logger.debug '乖離率が高いので中止しました'
          return false
        end

        unless store_status_ok?
          BF.logger.debug 'サーバに負荷がかかっているので中止しました'
          return false
        end
        return true
      end

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

require "bf/scalping/makiami"
require "bf/scalping/basic"
