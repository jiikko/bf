module BF
  class DaemonScalpingWorker < BaseWorker
    # 下記のときにBF::ScalpingWorkerを発動する
    # * 設定が有効になっていること
    # * 未完了(買い売り待ち)の取引がないこと(or 設定値よりも下のとき)
    # * キューにないこと
    def perform
      loop do
        run
        sleep(10)
      end
    end

    def run
      unless BF::Setting.enabled_daemon_sclping_worker?
        BF.logger.info "設定によって無効になっているのでちょっとsleepします"
        sleep(50)
        return
      end
      # キューに入っているか || Task.runingで検出される前の状態のタイミングを伺っている状態か
      if BF::ScalpingWorker.queueing? || BF::ScalpingWorker.doing?
        BF.logger.info "BF::ScalpingWorker.queueing? || BF::ScalpingWorker.doing? のどちらかがtrueなのでちょっとsleepします"
        sleep(50)
        return
      end
      if BF::ScalpingTask.running.count.zero?
        do_enqueue
        return
      else
        BF.logger.info "実行中(BF::ScalpingTask.running)のタスクがいるのでenqueしません"
      end

      # 通常は1つのみを稼働するけど設定値によっては複数個稼働する
      # 新しく起動する条件は、高値掴みしてしまってからn万以上離れた時
      if scalping_worker_count_under_max? && gap_price_over_limit?
        BF.logger.info "#{BF::ScalpingTask.running.count}個稼働中ですが BF::ScalpingWorker を enqueueしました"
        do_enqueue
        return
      end
    end

    # 手動での投入とDaemonScalpingWorkerからの投入を区別するために引数を渡す
    def do_enqueue
      BF::ScalpingWorker.perform_async("from" => self.class.to_s)
      BF.logger.info 'BF::ScalpingWorker を enqueueしました'
    end

    private

    def scalping_worker_count_under_max?
      BF::Setting.record.max_scalping_worker_count > BF::ScalpingTask.running.count
    end

    def gap_price_over_limit?
      BF::ScalpingTask.running.gap_price_from_current_to_last > 10_000
    end
  end
end
