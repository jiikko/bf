require 'spec_helper'

RSpec.describe BF::PreorderSnapshot do
  describe 'scopes' do
    describe 'summary' do
      it '所属するpreorderesの合計値を返すこと' do
        snapshot = BF::PreorderSnapshot.create!
        snapshot.preorders.create!(size: 0.01,
                                   price: 10,
                                   kind: BF::Preorder.kinds[:buy])
        snapshot.preorders.create!(size: 0.01,
                                   price: 10,
                                   kind: BF::Preorder.kinds[:buy])
        snapshot.preorders.create!(size: 0.01,
                                   price: 10,
                                   kind: BF::Preorder.kinds[:sell])
        summary = BF::PreorderSnapshot.summary
        expect(summary.to_a.count).to eq(1)
        record = summary.first
        expect(record.count_buy).to eq(2)
        expect(record.count_sell).to eq(1)
        expect(record.sum_size).to eq(0.03)
        expect(record.avg_price).to eq(10)
      end
    end
  end

  describe '#export_from_bf!' do
    let(:response_body) do
      [ {"id"=>0, "child_order_id"=>"a", "product_code"=>"FX_BTC_JPY", "side"=>"BUY", "child_order_type"=>"LIMIT", "price"=>3.0, "average_price"=>0.0, "size"=>0.1, "child_order_state"=>"ACTIVE", "expire_date"=>"2018-11-12T00:14:44", "child_order_date"=>"2018-10-13T00:14:44", "child_order_acceptance_id"=>"b", "outstanding_size"=>0.1, "cancel_size"=>0.0, "executed_size"=>0.0, "total_commission"=>0.0},
        {"id"=>0, "child_order_id"=>"a", "product_code"=>"FX_BTC_JPY", "side"=>"SELL", "child_order_type"=>"LIMIT", "price"=>9000.0, "average_price"=>0.0, "size"=>0.2, "child_order_state"=>"ACTIVE", "expire_date"=>"2018-11-12T00:14:44", "child_order_date"=>"2018-10-13T00:14:44", "child_order_acceptance_id"=>"b", "outstanding_size"=>0.1, "cancel_size"=>0.0, "executed_size"=>0.0, "total_commission"=>0.0},
      ].to_json
    end
    it 'レコードを作成すること' do
      http = double.as_null_object
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to \
        receive(:request).with(an_instance_of(Net::HTTP::Get))
        .and_return(OpenStruct.new(body: response_body))

      snapshot = BF::PreorderSnapshot.create!
      snapshot.export_from_bf!
      expect(snapshot.preorders.pluck(:kind, :size, :price)).to match_array([
        ["buy", 0.1e0, 3],
        ["sell", 0.2e0, 9000]
      ])
    end
  end
end
