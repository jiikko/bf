# 日をまたぐときにスワップポイントを払いたくなくて一時的に手放したあとに注文を待避するためのモデル
class BF::PreorderSnapshot < ::ActiveRecord::Base
  has_many :preorders

  def self.export_from_bf!(attrs={})
    list = BF::Preorder.current
    record = self.create!(memo: attrs[:memo])
    list.each do |hash|
      record.preorders.create!(hash)
    end
  end

  def import_to_bf!(id)
    preorders.each do |preorder|
      api_client.buy(preorder.price, preorder.size)
    end
    update!(restored: true)
  end

  def api_client
    @api_client ||= BF::Client.new
  end
end
