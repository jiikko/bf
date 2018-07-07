require 'spec_helper'

RSpec.describe BF::SummarizedMyTrade do
  describe 'summarize!' do
    it 'be success' do
      prev_day = 1.day.ago
      today = Time.now
      Factory.create_my_trade_ship(created_at: today)
      Factory.create_my_trade_ship(created_at: prev_day)
      Factory.create_my_trade_ship(created_at: prev_day)
      Factory.create_my_trade_ship(created_at: prev_day, by: :automation)

      prev_day_relation = BF::SummarizedMyTrade.where(summarized_on: prev_day.strftime('%Y/%m/%d'))
      today_relation = BF::SummarizedMyTrade.where(summarized_on: today.strftime('%Y/%m/%d'))
      expect(BF::SummarizedMyTrade.count).to eq(4)
      expect(today_relation.count).cout).to eq(1)
      expect(prev_day_relation.count).cout).to eq(3)
      prev_day_relation_table_by_kind = prev_day_relation.group_by(:kind)
      expect(prev_day_relation_table_by_kind[:manual].size).to eq(2)
      expect(prev_day_relation_table_by_kind[:automation].size).to eq(1)
    end

    context 'when has args' do
      it 'be success' do
        BF::MyTradeShip.create
      end
    end
  end
end
