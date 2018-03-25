require 'spec_helper'

RSpec.describe BF::Trade do
  describe '.fetch' do
    it '' do
      BF::Trade.delete_all
      BF::Trade.fetch
      expect(BF::Trade.count).to eq(1)
    end
  end

  describe '.minutely_range' do
    it 'だいたい上位とだいたい下位を返す' do
      BF::Trade.delete_all
      BF::Trade.create!(price: 1200, kind: :minutely, created_at: 2.minute.ago)
      BF::Trade.create!(price: 1100, kind: :hourly)
      [50, 90, 60, 60, 40, 100, 40, 40, 50, 70].each do |x|
        BF::Trade.create!(price: x, kind: :minutely)
      end
      expect(BF::Trade.minutely_range).to eq([40, 70])
    end
  end
end
