module BF
  class MyTrade < ::ActiveRecord::Base
    enum status: [:requesting, :succeed, :failed, :timeout, :error]
    enum kind: [:buy, :sell]

    has_one :trade_ship, class_name: 'BF::MyTradeShip', foreign_key: :buy_trade_id
    has_one :sell_trade, class_name: 'BF::MyTrade', through: :trade_ship, source: :sell_trade

    # 買いから入る
    def self.trade_from_buy!(target_price=nil)
      buy_trade = self.new
      target_price ||= buy_trade.api_client.min_price_by_current_range
      buy_trade.update!(price: target_price, size: 0.005, status: :requesting, kind: :buy)
      buy_trade.create_trade_ship!
      begin
        order_id = buy_trade.api_client.buy(target_price)
        buy_trade.update!(order_id: order_id, status: :succeed)
        buy_trade.run_sell_trade!
      rescue => e
        buy_trade.update!(error_trace: e.inspect, status: :error)
      end
      buy_trade
    end

    def run_sell_trade!
      sell_trade = BF::MyTrade.create!(price: self.price + range, size: 0.005, status: :requesting, kind: :sell)
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

    def api_client
      @client ||= BF::Client.new
    end
  end
end
