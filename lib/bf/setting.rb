module BF
  class Setting < ::ActiveRecord::Base
    class << self
      def enable_fetch?
        record.enabled_fetch?
      end

      def enable_fetch!
        record.update!(enabled_fetch: true)
      end

      def disable_fetch!
        record.update!(enabled_fetch: false)
      end

      def record
        BF::Setting.first || BF::Setting.create!
      end
    end
  end
end
