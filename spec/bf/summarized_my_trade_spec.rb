require 'spec_helper'

RSpec.describe BF::SummarizedMyTrade do
  describe 'summarize!' do
    it '集計できること' do
      prev_day = 1.day.ago
      today = Time.now
      Factory.create_my_trade_ship(created_at: 3.days.ago)
      Factory.create_my_trade_ship(created_at: today)
      Factory.create_my_trade_ship(created_at: prev_day)
      Factory.create_my_trade_ship(created_at: prev_day)
      Factory.create_my_trade_ship(created_at: prev_day, by: :manual)
      BF::SummarizedMyTrade.summarize!

      _3days_ago_relation = BF::SummarizedMyTrade.where(summarized_on: 3.days.ago.strftime('%Y/%m/%d'))
      prev_day_relation = BF::SummarizedMyTrade.where(summarized_on: prev_day.strftime('%Y/%m/%d'))
      today_relation = BF::SummarizedMyTrade.where(summarized_on: today.strftime('%Y/%m/%d'))

      manual_prev_day_relation = prev_day_relation.find { |x| x.kind == "manual" }
      expect(manual_prev_day_relation.count).to eq(1)
      expect(manual_prev_day_relation.profit).to eq(10)

      automation_prev_day_relation = prev_day_relation.find { |x| x.kind == "automation" }
      expect(automation_prev_day_relation.count).to eq(2)
      expect(automation_prev_day_relation.profit).to eq(20)

      expect(_3days_ago_relation.count).to eq(0)
    end

    context '集計範囲を変更する時' do
      it '集計範囲を変更することができること' do
        prev_day = 1.day.ago
        today = Time.now
        Factory.create_my_trade_ship(created_at: 3.days.ago)
        Factory.create_my_trade_ship(created_at: today)
        Factory.create_my_trade_ship(created_at: prev_day)
        Factory.create_my_trade_ship(created_at: prev_day)
        Factory.create_my_trade_ship(created_at: prev_day, by: :manual)
        BF::SummarizedMyTrade.summarize!(ago_days: 3.day)

        _3days_ago_relation = BF::SummarizedMyTrade.where(summarized_on: 3.days.ago.strftime('%Y/%m/%d'))
        prev_day_relation = BF::SummarizedMyTrade.where(summarized_on: prev_day.strftime('%Y/%m/%d'))
        today_relation = BF::SummarizedMyTrade.where(summarized_on: today.strftime('%Y/%m/%d'))

        manual_prev_day_relation = prev_day_relation.find { |x| x.kind == "manual" }
        expect(manual_prev_day_relation.count).to eq(1)
        expect(manual_prev_day_relation.profit).to eq(10)

        automation_prev_day_relation = prev_day_relation.find { |x| x.kind == "automation" }
        expect(automation_prev_day_relation.count).to eq(2)
        expect(automation_prev_day_relation.profit).to eq(20)

        relation = _3days_ago_relation.find { |x| x.kind == "automation" }
        expect(relation.count).to eq(1)
        expect(relation.profit).to eq(10)
      end
    end
  end
end
