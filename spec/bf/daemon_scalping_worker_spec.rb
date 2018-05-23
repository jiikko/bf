require 'spec_helper'

RSpec.describe BF::DaemonScalpingWorker do
  before do
    BF::MyTrade.delete_all
    BF::ScalpingTask.delete_all
    ResqueSpec.reset!
    allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
  end

  describe '#run' do
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
