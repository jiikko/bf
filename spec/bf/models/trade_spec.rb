require 'spec_helper'

RSpec.describe BF::Trade do
  describe '.fetch' do
    it do
      allow_any_instance_of(Net::HTTP).to receive(:start) do
        OpenStruct.new(body: { 'ltp' => 8 }.to_json)
      end
      BF::Trade.delete_all
      BF::Trade.fetch
      expect(BF::Trade.count).to eq(1)
    end
  end

  describe '.minutely_range' do
    it 'だいたい上位とだいたい下位を返す' do
      BF::Trade.delete_all
      BF::Trade.create!(price: 1200, created_at: 2.minute.ago)
      [50, 90, 60, 60, 40, 100, 40, 40, 50, 70].each do |x|
        BF::Trade.create!(price: x)
      end
      expect(BF::Trade.minutely_range).to eq([40, 70])
    end
  end
end
