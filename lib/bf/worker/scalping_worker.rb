module BF
  class ScalpingWorker < BaseWorker
    def perform(options = nil)
      scalping = BF::Scalping.new
      loop do
        if scalping.scalp
          break
        end
        sleep(5)
      end
    end

    class << self
      def queueing?
        result = !!Resque.peek("normal", 0, 100).detect { |hash|
          /#{self.to_s}/ =~ hash['class'] &&
            hash['args'].first.is_a?(Hash) &&
            unique_enqueued_class_regep =~ hash['args'].first['from']
        } || false
        return result

        # こうしたい
        # ResqueHelper.queueing?('normal',
        #                        /#{self.to_s}/,
        #                        [{from: unique_enqueued_class_regep}])
      end

      private

      def unique_enqueued_class_regep
        /DaemonScalpingWorker$/
      end
    end
  end
end
