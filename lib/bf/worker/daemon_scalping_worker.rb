module BF
  class DaemonScalpingWorker < BaseWorker
    # 下記のときにBF::ScalpingWorkerを発動する
    # * 設定が有効になっていること
    # * 未完了(買い売り待ち)の取引がないこと
    # * キューにないこと
    def perform
      loop do
        unless BF::Setting.enabled_daemon_sclping_worker?
          sleep(5)
          next
        end
        if BF::ScalpingTask.running?
          sleep(5)
          next
        end

        if BF::ScalpingWorker.queueing? || BF::ScalpingWorker.doing?
          sleep(5)
          next
        end
        do_enqueue
        sleep(2)
      end
    end

    def do_enqueue
      BF::ScalpingWorker.perform_async("from" => self.class.to_s)
      BF.logger.info 'BF::ScalpingWorker を enqueueしました'
    end
  end
end
