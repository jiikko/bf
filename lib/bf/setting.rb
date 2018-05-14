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

      def enabled_daemon_sclping_worker
        record.enabled_daemon_sclping_worker
      end

      def toggle_enabled_daemon_sclping_worker!
        record.toggle(:enabled_daemon_sclping_worker)
      end
    end
  end
end
