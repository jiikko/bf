module BF
  class DaemonScalpingWorker < BaseWorker
    # * 設定が有効になっていること
    # * 未完了(買い売り待ち)の取引がないこと
    # * スキャ
    def perform
      scalping = BF::Scalping.new
      loop do
        unless BF::Setting.enabled_daemon_sclping_worker?
          sleep(5)
          next
        end
        if BF::ScalpingTask.running?
          sleep(5)
          next
        end

        unless queueing?
          sleep(5)
          next
        end
        do_enqueue
        sleep(2)
      end
    end

    def do_enqueue
      BF::ScalpingWorker.perform_async("from" => self.class.to_s)
    end
  end
end
