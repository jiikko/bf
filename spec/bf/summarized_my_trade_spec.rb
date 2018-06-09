require 'spec_helper'
require "active_support/testing/time_helpers"

RSpec.describe BF::SummarizedMyTrade do
  include ActiveSupport::Testing::TimeHelpers

  describe '.summarize!' do
    it 'レコードを作ること' do
      # manual
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.01, status: :succeed, kind: :buy)
      sell_trade = BF::MyTrade.create!(price: 201, size: 0.01, status: :succeed, kind: :sell)
      closed_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade, created_at: 1.day.ago, created_at: '2012-01-01 02:00:00'.to_time)
      # automation
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.01, status: :succeed, kind: :buy)
      sell_trade = BF::MyTrade.create!(price: 201, size: 0.01, status: :succeed, kind: :sell)
      closed_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade, created_at: '2012-01-01 02:00:00'.to_time)
      closed_ship.create_scalping_task!

      # manual
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.01, status: :succeed, kind: :buy)
      sell_trade = BF::MyTrade.create!(price: 201, size: 0.01, status: :succeed, kind: :sell)
      closed_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade, created_at: '2012-01-02 02:00:00'.to_time)
      # manual
      buy_trade  = BF::MyTrade.create!(price: 1, size: 0.01, status: :succeed, kind: :buy)
      sell_trade = BF::MyTrade.create!(price: 201, size: 0.01, status: :succeed, kind: :sell)
      closed_ship = BF::MyTradeShip.create!(sell_trade: sell_trade, buy_trade: buy_trade, created_at: '2012-01-02 02:00:00'.to_time)

      travel_to('2012-01-02 03:00:00'.to_date) do
        BF::SummarizedMyTrade.summarize!(ago_days: 3.days)
        expect(BF::SummarizedMyTrade.all.map { |x| x.slice(:kind, :profit, :count, :summarized_on) }).to match_array([
          {"kind"=>"manual", "profit"=>2, "count"=>1, "summarized_on"=>'2012-01-01'.to_date},
          {"kind"=>"automation", "profit"=>2, "count"=>1, "summarized_on"=>'2012-01-01'.to_date},
          {"kind"=>"manual", "profit"=>4, "count"=>2, "summarized_on"=>'2012-01-02'.to_date},
          {"kind"=>"automation", "profit"=>0, "count"=>0, "summarized_on"=>'2012-01-02'.to_date},
        ])
      end
    end
  end
end
