# 日をまたぐときにスワップポイントを払いたくなくて一時的に手放したあとに注文を待避するためのモデル
class BF::PreorderSnapshot < ::ActiveRecord::Base
  has_many :preorders

  def self.fetch_from_bf!(attrs={})
    list = BF::Preorder.current
    record = self.create!(memo: attrs[:memo])
    list.each do |hash|
      record.preorders.create!(hash)
    end
  end

  def restore_to_bf!(id)
  end
end
