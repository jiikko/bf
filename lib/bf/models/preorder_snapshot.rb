# 日をまたぐときにスワップポイントを払いたくなくて一時的に手放したあとに注文を待避するためのモデル
class BF::PreorderSnapshot < ::ActiveRecord::Base
  has_many :preorders, dependent: :destroy

  scope :summary, ->{
    joins(:preorders).
    group('preorder_snapshots.id',
          'preorder_snapshots.created_at',
          'memo').
    select('sum(preorders.size) as sum_size',
           'avg(preorders.price) as avg_price',
           'count(case when kind=0 then 1 else null end ) as count_buy',
           'count(case when kind=1 then 1 else null end ) as count_sell',
           'preorder_snapshots.id',
           'preorder_snapshots.created_at',
           'memo')
  }

  def self.order_empty?
    BF::Preorder.current.empty?
  end

  def export_from_bf!(memo: nil)
    list = BF::Preorder.current
    list.each do |hash|
      self.preorders.create!(hash)
    end
  end

  def import_to_bf!
    preorders.order(price: :desc).each do |preorder|
      preorder.call_buy_or_sell_api!
    end
    update!(restored: true)
  end
end
