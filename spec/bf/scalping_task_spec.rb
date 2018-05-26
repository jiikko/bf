require 'spec_helper'

RSpec.describe BF::ScalpingTask do
  before(:each) do
    allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
  end

  describe '.running' do
    it 'return running record' do
      buy_trade = BF::MyTrade.new.run_buy_trade!(10)
      running_task = BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)

      buy_trade = BF::MyTrade.new.run_buy_trade!(10)
      BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
      buy_trade.succeed!
      buy_trade.trade_ship.sell_trade.succeed!

      expect(BF::ScalpingTask.running.ids).to eq([running_task.id])
    end
  end

  describe '.running?' do
    context '実行中ステータスのtaskがある時' do
      context '注文した直後の時' do
        it 'return true' do
          buy_trade = BF::MyTrade.new.run_buy_trade!(10)
          BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
          expect(BF::ScalpingTask.running?).to eq(true)
        end
      end
    end
    context '買いが約定した直後(売り約定待ち)の時' do
      it 'return true' do
        buy_trade = BF::MyTrade.new.run_buy_trade!(10)
        BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
        buy_trade.succeed!
        buy_trade.trade_ship.sell_trade.waiting_to_sell!
        expect(BF::ScalpingTask.running?).to eq(true)
      end
    end

    context '実行中ステータスのtaskがない時' do
      context '売りが約定した直後の時' do
        it 'return false' do
          buy_trade = BF::MyTrade.new.run_buy_trade!(10)
          BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
          buy_trade.succeed!
          buy_trade.trade_ship.sell_trade.succeed!
          expect(BF::ScalpingTask.running?).to eq(false)
        end
      end
    end

    context 'BF::ScalpingTaskレコードが無い時' do
      it 'return false' do
        expect(BF::ScalpingTask.count).to eq(0)
        expect(BF::ScalpingTask.running?).to eq(false)
      end
    end
  end

  describe '#running?' do
    context '紐づくtrade_shipがない時' do
      it 'return false' do
        task = BF::ScalpingTask.new
        expect(task.running?).to eq(false)
        expect(task.status).to eq(1)
      end
    end

    context '注文直後の取引がある時' do
      it 'return true' do
        buy_trade = BF::MyTrade.new.run_buy_trade!(10)
        task = BF::ScalpingTask.create!(trade_ship_id: buy_trade.trade_ship.id)
        expect(task.running?).to eq(true)
        expect(task.status).to eq(3)
      end
    end
  end
end
