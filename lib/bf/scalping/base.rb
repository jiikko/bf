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

        unless BF::Monitor.new.store_status_green?
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
    end
  end
end

require "bf/scalping/makiami"
require "bf/scalping/basic"
