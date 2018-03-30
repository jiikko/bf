require 'bf/engine'
require "active_record"
require "mysql2"
require "bf/version"
require "bf/monitor"
require "bf/client"
require "bf/trade"
require "bf/fetcher"
require "bf/cli"
require "bf/setting"
require "bf/my_trade"
require "bf/my_trade_ship"

module BF
  END_POINT = 'api.bitflyer.jp'
  PROCUT_CODE = 'FX_BTC_JPY'
end
