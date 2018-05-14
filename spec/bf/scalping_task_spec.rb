require 'spec_helper'

RSpec.describe BF::ScalpingTask do
  before do
    BF::MyTrade.delete_all
    BF::ScalpingTask.delete_all
    ResqueSpec.reset!
  end

  describe '.running?' do
    context '実行中ステータスのtaskがある時' do
      context '注文した直後の時' do
        it 'return true' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          buy_trade = BF::MyTrade.new.run_buy_trade!(10)
          BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
          expect(BF::ScalpingTask.running?).to eq(true)
        end
      end
    end
    context '買いが約定した直後の時' do
      it 'return true' do
        pending
      end
    end

    context '実行中ステータスのtaskがない時' do
      context '売りが約定した直後の時' do
        it 'return false' do
        pending
        end
      end
      it 'return false' do
        BF::MyTrade.delete_all
        BF::MyTradeShip.delete_all
        BF::ScalpingTask.delete_all
        expect(BF::ScalpingTask.running?).to eq(false)
      end
    end
  end
end
