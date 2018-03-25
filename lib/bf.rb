require "active_record"
require "mysql2"
require "bf/version"
require "bf/monitor"
require "bf/client"
require "bf/trade"
require "bf/cli"

module BF
  END_POINT = 'api.bitflyer.jp'
  PROCUT_CODE = 'FX_BTC_JPY'
end
