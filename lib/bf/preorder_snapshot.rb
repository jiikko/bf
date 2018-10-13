# 日をまたぐときにスワップポイントを払いたくなくて一時的に手放したあとに注文を待避するためのモデル
class BF::PreorderSnapshot < ::ActiveRecord::Base
  has_many :preorders

  def export_from_bf!(memo: nil)
    list = BF::Preorder.current
    list.each do |hash|
      self.preorders.create!(hash)
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
