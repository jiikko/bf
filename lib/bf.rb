require 'json'
require 'bf/engine'
require "logger"
require "active_record"
require "mysql2"
require "resque"
require "bf/version"
require "bf/monitor"
require "bf/client"
require "bf/trade"
require "bf/fetcher"
require "bf/cli"
require "bf/setting"
require "bf/my_trade"
require "bf/my_trade_ship"
require "bf/worker/base_worker"
require "bf/worker/order_waiting_worker"
require "bf/worker/selling_trade_worker"
require "bf/initialize/resque"
require "bf/worker/test_worker"

module BF
  END_POINT = 'api.bitflyer.jp'
  PROCUT_CODE = 'FX_BTC_JPY'

  class << self
    def logger
      @logger ||=
        if ENV['RUN_ENV'] == 'test'
          Logger.new("log_test.log")
        else
          Logger.new("log_development.log")
        end
    end

    def logger=(logger)
      @logger = logger
    end
  end
end
