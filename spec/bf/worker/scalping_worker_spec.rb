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
    end

    context 'nothing args and queued BF::ScalpingWorker ' do
      it 'return false' do
      end
    end
  end
end
