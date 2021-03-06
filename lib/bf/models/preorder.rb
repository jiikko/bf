class BF::Preorder < ::ActiveRecord::Base
  enum kind: [:buy, :sell]

  def self.current
    BF::Client::GetRegistratedOrders.new.run
  end

  def call_buy_or_sell_api!
    case
    when buy?
      api_client.buy(price, size)
    when sell?
      api_client.sell(price, size)
    end
  end

  private

  def api_client
    @api_client ||= BF::Client.new
  end
end
