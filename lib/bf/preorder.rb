class BF::Preorder < ::ActiveRecord::Base
  def self.current
    BF::Client::GetRegistratedOrders.new.run
  end
end

