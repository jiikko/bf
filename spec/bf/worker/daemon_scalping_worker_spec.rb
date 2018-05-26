require 'spec_helper'

RSpec.describe BF::DaemonScalpingWorker do
  let(:idol_worker) { OpenStruct.new(job: {}) }
  let(:target_job)  { OpenStruct.new(job: {"queue"=>"normal", "run_at"=>"2018-05-25T17:38:55Z", "payload"=>{"class"=>"BF::DaemonScalpingWorker", "args"=>[]}}) }
  let(:other_job1)  { OpenStruct.new(job: {"queue"=>"normal", "run_at"=>"2018-05-25T17:38:55Z", "payload"=>{"class"=>"BF::ScalpingWorker", "args"=>[]}}) }
  let(:other_job2)  { OpenStruct.new(job: {"queue"=>"normal", "run_at"=>"2018-05-25T17:38:55Z", "payload"=>{"class"=>"BF::DaemonWorker", "args"=>[]}}) }

  describe '.doing?' do
    context '実行中の自分自身のジョブがないとき' do
      before do
        allow(Resque).to receive(:workers).and_return([
          idol_worker, other_job1, other_job2, 
        ])
      end
      it 'return false' do
        expect(BF::DaemonScalpingWorker.doing?).to eq(false)
      end
    end

    context 'workerがいないとき' do
      before do
        allow(Resque).to receive(:workers).and_return([])
      end
      it 'be return' do
        expect(BF::DaemonScalpingWorker.doing?).to eq(false)
      end
    end

    context 'workerが実行中のジョブがあるとき' do
      before do
        allow(Resque).to receive(:workers).and_return([
          idol_worker, idol_worker, idol_worker, target_job, other_job1,
        ])
      end
      it 'return true' do
        expect(BF::DaemonScalpingWorker.doing?).to eq(true)
      end
    end
  end

  describe '#run' do
    before do
      allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
    end

    context 'BF::Setting.record.max_scalping_worker_count が 1の時' do
      before do
        BF::Setting.record.update!(max_scalping_worker_count: 1)
        BF::Setting.record.update!(enabled_daemon_sclping_worker: true)
      end
      context '稼働中のtaskが0個の時' do
        it 'do do_enqueue' do
          BF::DaemonScalpingWorker.new.run
          expect(BF::ScalpingWorker.queueing?).to eq(true)
          expect(BF::ScalpingWorker.doing?).to eq(false)
          expect(BF::ScalpingTask.running.count).to eq(0)
        end
      end
    end

    context 'BF::Setting.record.max_scalping_worker_count が 1の時' do
      before do
        BF::Setting.record.update!(max_scalping_worker_count: 1)
        BF::Setting.record.update!(enabled_daemon_sclping_worker: true)
      end
      context '稼働中のtaskが1個の時' do
        before do
          buy_trade = BF::MyTrade.new.run_buy_trade!(90_000)
          BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id) # 1つ稼働している
        end
        it 'do not do_enqueue' do
          BF::DaemonScalpingWorker.new.run
          expect(BF::ScalpingWorker.queueing?).to eq(false)
          expect(BF::ScalpingWorker.doing?).to eq(false)
          expect(BF::ScalpingTask.running.count).to eq(1)
        end
      end
    end

    context 'BF::Setting.record.max_scalping_worker_count が 2の時' do
      before do
        BF::Setting.record.update!(max_scalping_worker_count: 2)
        BF::Setting.record.update!(enabled_daemon_sclping_worker: true)
      end
      context '稼働中のtaskが1個の時' do
        before do
          # 最終に買った価格が9万
          buy_trade = BF::MyTrade.new.run_buy_trade!(90_000)
          BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
        end

        context '最新taskの取引価格と現在価格が2万離れている時' do
          before do
            # 最終取引価格が7万
            BF::Trade.create!(price: 70_000, kind: :minutely)
            expect(BF::ScalpingTask.running.gap_price_from_current_to_last).to eq(20_000)
          end
          it 'do do_enqueue(in queue yet)' do
            BF::DaemonScalpingWorker.new.run
            expect(BF::ScalpingWorker.queueing?).to eq(true)
            expect(BF::ScalpingWorker.doing?).to eq(false)
            expect(BF::ScalpingTask.running.count).to eq(1)
          end
        end

        context '最新taskの取引価格と現在価格が5千離れている時' do
          before do
            # 最終取引価格が7万
            BF::Trade.create!(price: 85_000, kind: :minutely)
            expect(BF::ScalpingTask.running.gap_price_from_current_to_last).to eq(5_000)
          end
          it 'do not do_enqueue' do
            BF::DaemonScalpingWorker.new.run
            expect(BF::ScalpingWorker.queueing?).to eq(false)
            expect(BF::ScalpingWorker.doing?).to eq(false)
            expect(BF::ScalpingTask.running.count).to eq(1)
          end
        end
      end
    end
  end
end
