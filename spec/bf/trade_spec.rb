require 'spec_helper'

RSpec.describe BF::Trade do
  describe 'minutely_range' do
    it do
      BF::Trade.create!(price: 1200, kind: :minutely, created_at: 2.minute.ago)
      BF::Trade.create!(price: 1100, kind: :hourly)
      BF::Trade.create!(price: 1000, kind: :minutely)
      BF::Trade.create!(price: 300, kind: :minutely)
      BF::Trade.create!(price: 500, kind: :minutely)
      expect(BF::Trade.minutely_range).to eq([1000, 300])
    end
  end
end
