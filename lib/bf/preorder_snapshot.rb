# 日をまたぐときにスワップポイントを払いたくなくて一時的に手放したあとに注文を待避するためのモデル
class BF::PreorderSnapshot < ::ActiveRecord::Base
  has_many :preorders

  def self.export_from_bf!(memo: nil)
    list = BF::Preorder.current
    record = self.create!(memo: memo)
    list.each do |hash|
      record.preorders.create!(hash)
    end
  end

  def import_to_bf!(id)
    preorders.each do |preorder|
      preorder.call_buy_or_sell_api!
    end
    update!(restored: true)
  end

  def order_empty?
    BF::Preorder.current.empty?
  end
end
