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

    has_one :trade_ship, class_name: 'BF::MyTradeShip', foreign_key: :buy_trade_id, dependent: :destroy
    has_one :sell_trade, class_name: 'BF::MyTrade', through: :trade_ship, source: :sell_trade
    has_one :buy_trade, class_name: 'BF::MyTrade', through: :trade_ship, source: :buy_trade

    def run_buy_trade!(target_price=nil)
      target_price ||= api_client.min_price_by_current_range
      update!(price: target_price, size: order_size, status: :waiting_to_request, kind: :buy)
      begin
        order_id = api_client.buy(target_price, order_size) # まだ約定していない
        update!(order_id: order_id, status: :requested)
      rescue => e
        update!(error_trace: e.inspect, status: :error)
        return self
      end
      create_sell_trade!
      OrderWaitingWorker.async_perform(self.id)
      SellingTradeWorker.async_perform(self.id)
      self
    end

    def run_sell_trade!
      return if canceled?
      begin
        order_id = sell_trade.api_client.sell(sell_trade.price, sell_trade.order_size)
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
      current_status = BF::Client.new.get_order(self.order_id)
      case current_status
      when 'COMPLETED'
        true
      when 'ACTIVE'
        false
      when nil # 注文した直後だとnil がくる
        false
      else # 'CANCELED', 'EXPIRED', 'REJECTED' が返ってくるのは想定外
        raise("エラー。買い注文の約低待ち中に 買い注文のステータスが #{current_status} が返ってきました。")
      end
    end

    def check_buy_trade
      begin
        Timeout.timeout(15.minutes) do
          loop do
            if trade_status_of_server? # TODO リアルタイムAPIを検討する
              succeed!
              break
            end
            if canceled?
              BF.logger.info "買い注文をポーリングしていましたが#{status}だったので中止しました。売り注文を出していません。"
              sell_trade.canceled_before_request!
              return
            end
            sleep(2)
          end
        end
      rescue Timeout::Error => e
        BF.logger.info "買い注文をポーリングしていましたがタイムアウトです。売り注文を出していません。"
        sell_trade.canceled_before_request!
        timeout_before_request!
        return
      end
    end

    private

    def create_sell_trade!
      raise("invalid kind, because I called from sell") if self.sell?
      ship = create_trade_ship!
      sell_trade_id = BF::MyTrade.create!(price: self.price + range, size: order_size, status: :waiting_to_buy, kind: :sell).id
      ship.update!(sell_trade_id: sell_trade_id)
    end
  end
end
