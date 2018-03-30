require 'net/https'
require 'json'

module BF
  # https://lightning.bitflyer.jp/docs?lang=ja#http-public-api
  class Client
    class << self
      def get_state
        new.get("/v1/getboardstate", PROCUT_CODE)
      end

      def get_ticker
        new.get("/v1/ticker", PROCUT_CODE)
      end
    end

    def get(path, product_code)
      pt = "#{path}?PRODUCT_CODE=#{product_code}"
      https = Net::HTTP.new(END_POINT, 443)
      https.use_ssl = true
      body = nil
      begin
        body = https.start { |https| response = https.get(pt) }.body
      rescue OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Errno::ECONNRESET,  Errno::EHOSTUNREACH => e
        retry
      end
      JSON.parse(body)
    end

    def buy(price)
    end

    def sell(price)
    end

    def min_price_by_current_range
    end
  end
end
