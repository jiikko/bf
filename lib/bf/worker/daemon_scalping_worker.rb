module BF
  class DaemonScalpingWorker < BaseWorker
    def perform
      scalping = BF::Scalping.new
      loop do
        unless BF::Setting.enabled_daemon_sclping_worker
          sleep(5)
          next
        end
        if ScalpingTask.running?
          sleep(5)
          next
        end
        BF::ScalpingWorker.perform_async
      end
    end
  end
end
