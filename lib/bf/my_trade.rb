module BF
  class MyTrade < ::ActiveRecord::Base
    enum status: [
      :waiting_to_request,
      :waiting_to_buy,
      :requested,
      :requesting,
      :succeed,
      :failed,
      :timeout,
      :error,
      :canceled,
      :canceled_before_request,
      :timeout_before_request,
    ]
    enum kind: [:buy, :sell]

    has_one :trade_ship, class_name: 'BF::MyTradeShip', foreign_key: :buy_trade_id
    has_one :sell_trade, class_name: 'BF::MyTrade', through: :trade_ship, source: :sell_trade
    has_one :buy_trade, class_name: 'BF::MyTrade', through: :trade_ship, source: :buy_trade

    # 買いから入る
    def self.trade_from_buy!(target_price=nil)
      BuyingTradeWorker.async_perform(my_trade_id)
    end

    def run_buy_trade!(target_price=nil)
      target_price ||= api_client.min_price_by_current_range
      update!(price: target_price, size: order_size, status: :waiting_to_request, kind: :buy)
      begin
        order_id = api_client.buy(target_price) # まだ成約していない
        update!(order_id: order_id, status: :requested)
      rescue => e
        update!(error_trace: e.inspect, status: :error)
        return self
      end
      create_sell_trade!
      SellingTradeWorker.async_perform(self.id)
      check_buy_trade # 買い注文が成約したかをチェックする
      self
    end

    def run_sell_trade!
      return if canceled?
      sell_trade = BF::MyTrade.create!(price: self.price + range, size: order_size, status: :requesting, kind: :sell)
      self.trade_ship.update!(sell_trade_id: sell_trade.id)
      begin
        order_id = sell_trade.api_client.buy(sell_trade.price)
        sell_trade.update!(order_id: order_id, status: :succeed)
      rescue => e
        sell_trade.update!(error_trace: e.inspect, status: :error)
      end
    end

    # TODO
    def range
      400
    end

    def order_size
      0.005
    end

    def api_client
      @client ||= BF::Client.new
    end

    def trade_status_of_server?
      # api_client に問い合わせて注文が通ったか確認をする
    end

    private

    def create_sell_trade!
      raise("invalid kind, because I called from sell") if self.sell?
      ship = create_trade_ship!
      sell_trade_id = BF::MyTrade.create!(price: self.price + range, size: order_size, status: :waiting_to_buy, kind: :sell).id
      ship.update!(sell_trade_id: sell_trade_id)
    end

    def check_buy_trade
      begin
        Timeout.timeout(10.minutes) do
          loop do
            if buy_trade.trade_status_of_server? # TODO リアルタイムAPIを検討する
              buy_trade.succeed!
              break
            end
            if buy_trade.error? || buy_trade.canceled?
              BF.logger.info "買い注文をポーリングしていましたが#{buy_trade.status}だったので中止しました。売り注文を出していません。"
              buy_trade.sell_trade.canceled_before_request!
              return
            end
            sleep(0.5)
          end
        end
      rescue Timeout::Error => e
        buy_trade.sell_trade.timeout_before_request!
        return
      end
    end
  end
end
