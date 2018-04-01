require 'net/https'
require "openssl"
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

    def initialize(path: nil)
      path =
        if defined?(Rails)
          path = File.join(Rails.root, 'bf_config.yaml')
        else
          path ||= 'bf_config.yaml'
        end
      @config = YAML.load(File.open(path))
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
      rescue Timeout::Error
        sleep(5)
        retry
      end
      JSON.parse(body)
    end

    def buy(price, size)
      default_body = {
        product_code: PROCUT_CODE,
        child_order_type: 'LIMIT',
        side: 'BUY',
      }
      body = default_body.merge(price: price, size: size).to_json
      method = 'POST'
      timestamp = Time.now.to_i.to_s
      uri = URI.parse("https://#{END_POINT}")
      uri.path = '/v1/me/sendchildorder'
      text = [timestamp, method, uri.request_uri, body].join
      sign = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), api_secret, text)
      options = Net::HTTP::Post.new(uri.request_uri, initheader = {
        "ACCESS-KEY" => api_key,
        "ACCESS-TIMESTAMP" => timestamp,
        "ACCESS-SIGN" => sign,
        "Content-Type" => "application/json",
      })
      options.body = body
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      response = https.request(options)
      puts response.body
    end

    def sell(price)
    end

    def api_key
      @config['api_key']
    end

    def api_secret
      @config['api_secret']
    end
  end
end
