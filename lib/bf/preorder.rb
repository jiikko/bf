class BF::Preorder < ::ActiveRecord::Base
  enum kind: [:buy, :sell]

  def self.current
    BF::Client::GetRegistratedOrders.new.run
  end
end
