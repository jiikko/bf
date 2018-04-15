require 'spec_helper'

RSpec.describe BF::MyTrade do
  before do
    ResqueSpec.reset!
  end

  describe '.run_buy_trade!' do
    context "client.buyでエラーが起きた時" do
      it "sell_tradeを作ること" do
        allow_any_instance_of(BF::SellingTradeWorker).to receive(:perform)
        allow_any_instance_of(BF::Client).to receive(:buy) { raise }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(buy_trade.error?).to eq(true)
        expect(buy_trade.sell_trade).to be_a(BF::MyTrade)
        expect(ResqueSpec.queues['normal'].size).to eq(0)
      end
    end
    context '買いの約定待ちがタイムアウトを迎えた時' do
      it '買い売り注文を売り出さずにキャンセルステータスにする' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::Client).to receive(:cancel_order)
        allow_any_instance_of(BF::MyTrade).to receive(:created_at) { 16.minutes.ago }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        ResqueSpec.run!('normal')
        expect(buy_trade.reload.timeout?).to eq(true)
        expect(buy_trade.sell_trade.canceled_before_request?).to eq(true)
      end
    end
    context '買いの約定待ちに 買い注文が canceled? になった時' do
      it '買い売り注文を売り出さずにキャンセルステータスにする' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        # 約定待ちになってほしいのでACTIVEを返す
        allow_any_instance_of(BF::Client).to receive(:get_order).and_return(nil)
        allow_any_instance_of(BF::MyTrade).to receive(:canceled?) { true }
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        ResqueSpec.run!('normal')
        expect(buy_trade.sell_trade.canceled_before_request?).to eq(true)
      end
    end
    context '買い注文を出した時' do
      context '発注してからキャンセルになったら' do
        it '買い注文と売り注文を取り下げる' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        end
      end
      it 'pairのmy_tradeを作成すること' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:check_buy_trade)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(ResqueSpec.queues['normal'].map { |x| x[:class] }).to eq(["BF::SellingTradeWorker"])
        expect(buy_trade.price).to eq(300)
        expect(buy_trade.buy?).to eq(true)
        expect(buy_trade.requested?).to eq(true)
        expect(buy_trade.sell_trade.price).to eq(700)
        expect(buy_trade.sell_trade.sell?).to eq(true)
        expect(buy_trade.sell_trade.waiting_to_sell?).to eq(true)
      end
      it '買いが約定しないと売りを発注しない' do
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        allow_any_instance_of(BF::MyTrade).to receive(:check_buy_trade)
        buy_trade = BF::MyTrade.new.run_buy_trade!(300)
        expect(ResqueSpec.queues['normal'].size).to eq(1)
        expect(buy_trade.sell_trade.waiting_to_sell?).to eq(true)
        begin
          Timeout.timeout(1) do
            ResqueSpec.run!('normal')
            expect(true).to eq(false) # 正しくブロッキングされているなら実行しない
          end
        rescue Timeout::Error
        end
      end

      context '買い注文が約定した時' do
        it 'buy_trade.succeed! になること' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          allow_any_instance_of(BF::MyTrade).to receive(:trade_sccessd?).and_return(true)
          allow(BF::MyTrade).to receive(:tries_count).and_return(1)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
          expect(buy_trade.order_acceptance_id).to eq('1')
          ResqueSpec.run!('normal')
          expect(buy_trade.reload.succeed?).to eq(true)
        end
        it '売りを発注すること(run_sell_trade!)' do
          allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
          allow_any_instance_of(BF::Client).to receive(:sell).and_return(1)
          allow_any_instance_of(BF::MyTrade).to receive(:trade_sccessd?).and_return(true)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
          expect(ResqueSpec.queues['normal'].map { |x| x[:class] }).to eq([ "BF::SellingTradeWorker"])
          ResqueSpec.run!('normal')
          expect(buy_trade.reload.succeed?).to eq(true)
          expect(buy_trade.sell_trade.selling?).to eq(true)
          expect(buy_trade.order_acceptance_id).to eq('1')
          expect(buy_trade.order_id).to eq(nil)
          expect(buy_trade.sell_trade.order_id).to eq(nil)
          expect(buy_trade.sell_trade.order_acceptance_id).not_to eq(nil)
        end
        context "client.sellでエラーが起きた時" do
          it 'sell_trade.status が error になること' do
            allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
            allow(BF::MyTrade).to receive(:tries_count).and_return(1)
            allow_any_instance_of(BF::Client).to receive(:sell) { raise('Timeout::Error') }
            allow_any_instance_of(BF::MyTrade).to receive(:trade_sccessd?).and_return(true)
            buy_trade = BF::MyTrade.new.run_buy_trade!(300)
            ResqueSpec.run!('normal')
            expect(buy_trade.reload.succeed?).to eq(true)
            expect(buy_trade.sell_trade.error?).to eq(true)
          end
        end
      end
    end
  end
  describe '#trade_sccessd?' do
    context 'order_id を持っている時' do
      it 'order_id で検索すること' do
        buy_trade = BF::MyTrade.new(kind: :buy, order_id: '1')
        api_client = double(:api_client)
        allow(api_client).to receive(:get_order).with(order_id: '1').once do
          { 'child_order_state' => 'COMPLETED' }
        end
        allow(buy_trade).to receive(:api_client).and_return(api_client)
        expect(buy_trade.trade_sccessd?).to eq(true)
      end
    end
    context 'order_acceptance_id と order_id の両方を持っている時' do
      it 'order_idで検索すること' do
        buy_trade = BF::MyTrade.new(kind: :buy, order_id: '1', order_acceptance_id: '2')
        api_client = double(:api_client)
        allow(api_client).to receive(:get_order).with(order_id: '1').once do
          { 'child_order_state' => 'COMPLETED' }
        end
        allow(buy_trade).to receive(:api_client).and_return(api_client)
        expect(buy_trade.trade_sccessd?).to eq(true)
      end
    end
    context 'order_acceptance_id のみを持っている時' do
      it 'order_acceptance_id で検索して、order_idをセットすること' do
        buy_trade = BF::MyTrade.new(kind: :buy, order_acceptance_id: '2', status: 0, price: 0, size: 0)
        api_client = double(:api_client)
        allow(api_client).to receive(:get_order).with(order_acceptance_id: '2').once do
          { 'child_order_state' => 'COMPLETED', 'child_order_id' => '1' }
        end
        allow(buy_trade).to receive(:api_client).and_return(api_client)
        expect(buy_trade.trade_sccessd?).to eq(true)
        expect(buy_trade.order_id).to eq('1')
      end
    end
  end
end
