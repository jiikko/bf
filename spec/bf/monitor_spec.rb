require 'spec_helper'

RSpec.describe BF::Monitor do
  describe '.state_const_with_number' do
    it 'be success' do
      expect(BF::Monitor.state_const_with_number).to eq({
        "取引所は停止しています。発注は受付されません。"=>0,
        "発注が受付できない状態です。"=>1,
        "負荷が非常に大きい状態です。発注は失敗するか、遅れて処理される可能性があります。"=>2,
        "取引所の負荷が大きい状態です。"=>3,
        "取引所に負荷がかかっている状態です。"=>4,
        "取引所は稼動しています。"=>5
      })
    end
  end
end
