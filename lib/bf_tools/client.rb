require 'net/https'
require 'json'

module BfTools
  END_POINT = 'api.bitflyer.jp'
  PROCUT_CODE = 'FX_BTC_JPY'

  class Client
    class << self
      def get_state
        new.get("/v1/getboardstate?product_code=#{PROCUT_CODE}")
      end
    end

    def get(path)
      https = Net::HTTP.new(END_POINT, 443)
      https.use_ssl = true
      body = https.start { |https| response = https.get(path) }.body
      JSON.parse(body)
    end
  end
end
