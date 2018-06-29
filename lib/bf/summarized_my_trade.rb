module BF
  class SummarizedMyTrade < ::ActiveRecord::Base
    enum kind: [:manual, :automation]

    def self.summarize!(ago_days: 2.day)
      if ago_days.is_a?(Integer)
        ago_days = ago_days.day
      end
      # TODO SQLでやる
      ships_table = BF::MyTradeShip.succeed.includes(:scalping_task, :buy_trade, :sell_trade).
        where("#{BF::MyTradeShip.table_name}.created_at > ?", (Time.now.beginning_of_day - ago_days)).order(created_at: :desc).
        group_by { |x| x.created_at.localtime.strftime('%Y/%m/%d') }

      ships_table.each do |date, tasks|
        hash = tasks.group_by { |x| x.scalping_task.nil? ? :manual : :automation }
        automation_list = hash[:automation] ||= []
        manual_list = hash[:manual] ||= []
        total_automations_profit = automation_list.map(&:profit).reduce(&:+).to_i
        total_manual_profit = manual_list.map(&:profit).reduce(&:+).to_i

        manual = self.find_or_create_by(summarized_on: date, kind: :manual)
        manual.update!(profit: total_manual_profit, count: manual_list.size)
        automation  = self.find_or_create_by(summarized_on: date, kind: :automation)
        automation.update!(profit: total_automations_profit, count: automation_list.size)
      end
    end
  end
end
