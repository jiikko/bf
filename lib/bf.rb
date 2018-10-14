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
require "bf/daemon"
require "bf/cli"
require "bf/resque_helper"
load_dir = %w(
  client
  initialize
  models
  scalping
  worker
)
load_dir.reduce([]) { |list, path|
  filepath = File.join(File.expand_path("../bf", __FILE__), path, "**.rb")
  list.concat Dir.glob(filepath)
}.each { |path| require path }

module BF
  class DisparityOverError < StandardError; end

  END_POINT = 'https://api.bitflyer.jp'
  BTC_FX_PRODUCT_CODE = 'FX_BTC_JPY'
  BTC_PRODUCT_CODE    = 'BTC_JPY'

  STOP_DISPARITY_LIMIT = 4.9

  class << self
    def logger
      @logger ||=
        if ENV['RUN_ENV'] == 'test'
          Logger.new("log/test.log", 0)
        else
          Logger.new("log/development.log", 0)
        end
    end

    def logger=(logger)
      @logger = logger
    end

    def scalping_worker_class
      Scalping::Basic
    end
  end
end
