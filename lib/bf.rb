require 'json'
require 'bf/engine'
require "logger"
require "active_record"
require "mysql2"
require "retryable"
require "resque"
require "bf/version"
require "bf/monitor"
require "bf/client"
require "bf/trade"
require "bf/fetcher"
require "bf/cli"
require "bf/scalping_task"
require "bf/setting"
require "bf/my_trade"
require "bf/my_trade_ship"
require "bf/worker/base_worker"
require "bf/worker/order_waiting_worker"
require "bf/worker/selling_trade_worker"
require "bf/worker/scalping_worker"
require "bf/initialize/resque"
require "bf/resque_helper"
require "bf/scalping"

module BF
  END_POINT = 'api.bitflyer.jp'
  PROCUT_CODE = 'FX_BTC_JPY'

  class << self
    def logger
      @logger ||=
        if ENV['RUN_ENV'] == 'test'
          Logger.new("log/test.log")
        else
          Logger.new("log/development.log")
        end
    end

    def logger=(logger)
      @logger = logger
    end
  end
end
