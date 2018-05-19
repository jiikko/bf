require 'spec_helper'

RSpec.describe BF::ScalpingWorker do
  before do
    ResqueSpec.reset!
  end

  describe '.queueing?' do
    context 'エンキュー済み' do
      it 'return true' do
        BF::DaemonScalpingWorker.new.do_enqueue
        expect(BF::ScalpingWorker.queueing?).to eq(true)
      end
    end
    context 'キューなし' do
      it 'return false' do
        expect(BF::ScalpingWorker.queueing?).to eq(false)
      end
    end


    context 'diff args and queued BF::ScalpingWorker ' do
      it 'return false' do
        BF::ScalpingWorker.perform_async("from" => 'hoge')
        expect(BF::ScalpingWorker.queueing?).to eq(false)
      end
    end

    context 'nothing args and queued BF::ScalpingWorker ' do
      it 'return false' do
        BF::ScalpingWorker.perform_async("from" => nil)
        expect(BF::ScalpingWorker.queueing?).to eq(false)
        BF::ScalpingWorker.perform_async("from" => [])
        expect(BF::ScalpingWorker.queueing?).to eq(false)
        BF::ScalpingWorker.perform_async("from" => '')
        expect(BF::ScalpingWorker.queueing?).to eq(false)
        BF::ScalpingWorker.perform_async("from" => {})
        expect(BF::ScalpingWorker.queueing?).to eq(false)
      end
    end
  end
end
