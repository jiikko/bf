require 'spec_helper'

RSpec.describe BF::MyTrade do
  describe '.run_buy_trade!' do
    context '乖離率が高い時' do
      it '注文しないこと' do
        Resque.redis.set(BF::Monitor::FETCH_DISPARITY_KEY, 5)
        buy_trade = BF::MyTrade.new.run_buy_trade!(1)
        expect(/DisparityOverError/ =~ buy_trade.error_trace).to be_a(Integer)
        expect(buy_trade.status).to eq('error')
        expect(buy_trade.trade_ship.sell_trade.canceled?).to eq(true)
      end
    end

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
        allow_any_instance_of(BF::Client).to receive(:get_order).and_return([{'size'=> 1}])
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

        allow_any_instance_of(Net::HTTP).to receive(:request) do
          sleep(2)
        end

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
          BF::Setting.record.update!(order_size: 0.001)
          buy_trade = BF::MyTrade.new.run_buy_trade!(300)
          expect(ResqueSpec.queues['normal'].map { |x| x[:class] }).to eq([ "BF::SellingTradeWorker"])
          ResqueSpec.run!('normal')
          buy_trade.reload
          expect(buy_trade.succeed?).to eq(true)
          expect(buy_trade.sell_trade.selling?).to eq(true)
          expect(buy_trade.order_acceptance_id).to eq('1')
          expect(buy_trade.sell_trade.size).to eq(0.001)
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

  describe '#running?' do
    it 'return true' do
      expect(BF::MyTrade.new(kind: :buy, status: 'requested').running?).to eq(true)
      expect(BF::MyTrade.new(kind: :sell, status: 'selling').running?).to eq(true)
      expect(BF::MyTrade.new(kind: :sell, status: 'error').running?).to eq(false)
    end
  end

  describe '#trade_sccessd?' do
    context 'レスポンスが空配列の時' do
      it 'falseを返すこと' do
        buy_trade = BF::MyTrade.new(kind: :buy, order_acceptance_id: '2', status: 0, price: 10, size: 0.1)
        api_client = double(:api_client)
        allow(api_client).to receive(:get_order).with(order_acceptance_id: '2').once { [] }
        allow(buy_trade).to receive(:api_client).and_return(api_client)
        expect(buy_trade.trade_sccessd?).to eq(false)
        expect(buy_trade.waiting_to_request?).to eq(true)
      end
    end
    context 'レスポンスのsizeが注文時のsizeと同じ時' do
      describe '桁落ちしない確認' do
        it 'trueを返すこと' do
          buy_trade = BF::MyTrade.new(kind: :buy, order_acceptance_id: '2', status: 0, price: 10, size: 0.05)
          api_client = double(:api_client)
          allow(api_client).to receive(:get_order).with(order_acceptance_id: '2').once do
            [{"child_order_id"=>"123", "child_order_acceptance_id"=>"445", "exec_date"=>"2018-08-01T23:57:10.803", "id"=>1, "price"=>10, "size"=>0.006},
             {"child_order_id"=>"123", "child_order_acceptance_id"=>"445", "exec_date"=>"2018-08-01T23:57:10.803", "id"=>1, "price"=>10, "size"=>0.044}]
          end
          allow(buy_trade).to receive(:api_client).and_return(api_client)
          expect(buy_trade.trade_sccessd?).to eq(true)
          expect(buy_trade.waiting_to_request?).to eq(true)
        end

        it 'trueを返すこと' do
          buy_trade = BF::MyTrade.new(kind: :buy, order_acceptance_id: '2', status: 0, price: 10, size: 0.3)
          api_client = double(:api_client)
          allow(api_client).to receive(:get_order).with(order_acceptance_id: '2').once do
            [{"child_order_id"=>"123", "child_order_acceptance_id"=>"445", "exec_date"=>"2018-08-01T23:57:10.803", "id"=>1, "price"=>10, "size"=>0.29477297},
             {"child_order_id"=>"123", "child_order_acceptance_id"=>"445", "exec_date"=>"2018-08-01T23:57:10.803", "id"=>1, "price"=>10, "size"=>0.00522703}]
          end
          allow(buy_trade).to receive(:api_client).and_return(api_client)
          expect(buy_trade.trade_sccessd?).to eq(true)
          expect(buy_trade.waiting_to_request?).to eq(true)
        end
      end
    end
    context 'レスポンスのsizeが注文時のsizeよりも小さい時' do
      context '最終取引価格から離れていない時' do
        it 'trueを返すこと, 取引量が約定分になっていること' do
          BF::Trade.create!(kind: :minutely, price: 2000)
          buy_trade = BF::MyTrade.new(kind: :buy, order_acceptance_id: '2', status: 0, price: 10, size: 1.05)
          buy_trade.save! && buy_trade.send(:create_sell_trade!)
          expect(buy_trade.size).to eq(1.05)
          expect(buy_trade.sell_trade.size).to eq(1.05)

          api_client = double(:api_client)
          allow(api_client).to receive(:cancel_order).with('2').once
          allow(api_client).to receive(:get_order).with(order_acceptance_id: '2').once do
            [{"child_order_id"=>"123", "child_order_acceptance_id"=>"445", "exec_date"=>"2018-08-01T23:57:10.803", "id"=>1, "price"=>10, "size"=>0.01971598}]
          end
          allow(buy_trade).to receive(:api_client).and_return(api_client)
          expect(buy_trade.trade_sccessd?).to eq(true)
          buy_trade.reload
          expect(buy_trade.parted_trading?).to eq(false)
          expect(buy_trade.size).to eq(0.01971598)
          expect(buy_trade.sell_trade.size).to eq(0.01971598)
          expect(buy_trade.price).to eq(10)
          expect(buy_trade.sell_trade.price).to eq(410)
        end
      end
      context '最終取引価格から離れていない時' do
        it 'falseを返すこと, 取引量が変わっていないこと' do
          buy_trade = BF::MyTrade.new(kind: :buy, order_acceptance_id: '2', status: 0, price: 10, size: 1.05)
          buy_trade.save! && buy_trade.send(:create_sell_trade!)
          expect(buy_trade.size).to eq(1.05)
          expect(buy_trade.sell_trade.size).to eq(1.05)

          api_client = double(:api_client)
          allow(api_client).to receive(:cancel_order).with('2').once
          allow(api_client).to receive(:get_order).with(order_acceptance_id: '2').once do
            [{"child_order_id"=>"123", "child_order_acceptance_id"=>"445", "exec_date"=>"2018-08-01T23:57:10.803", "id"=>1, "price"=>10, "size"=>0.006}]
          end
          allow(buy_trade).to receive(:api_client).and_return(api_client)
          expect(buy_trade.trade_sccessd?).to eq(false)
          buy_trade.reload
          expect(buy_trade.parted_trading?).to eq(true)
          expect(buy_trade.size).to eq(1.05)
          expect(buy_trade.sell_trade.size).to eq(1.05)
        end
      end
    end
  end
end
