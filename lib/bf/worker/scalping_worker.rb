module BF
  class ScalpingWorker < BaseWorker
    def perform(options = nil)
      loop do
        if BF::Scalping.new.scalp
          break
        end
        sleep(5)
      end
    end

    class << self
      def queueing?
        !!Resque.peek("normal", 0, 100).detect { |hash|
          check_payload?(hash)
        } || false

        # こうしたい
        # ResqueHelper.queueing?('normal',
        #                        /#{self.to_s}/,
        #                        [{from: unique_enqueued_class_regep}])
      end

      private

      def check_payload?(hash)
        /#{self.to_s}/ =~ hash['class'] &&
          hash['args'].first.is_a?(Hash) &&
          unique_enqueued_class_regep =~ (hash['args'].first['from'].presence || '')
      end

      def unique_enqueued_class_regep
        /DaemonScalpingWorker$/
      end
    end
  end
end
