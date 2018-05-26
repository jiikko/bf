require "bf/scalping/modules/validator"

module BF
  class Scalping
    class Base
      include BF::Scalping::Modules::Validator

      private

      def valid?
        if over_disparity?
          BF.logger.debug '乖離率が高いので中止しました'
          return false
        end

        unless store_status_ok?
          BF.logger.debug 'サーバに負荷がかかっているので中止しました'
          return false
        end
      end
    end
  end
end

require "bf/scalping/makiami"
require "bf/scalping/basic"
