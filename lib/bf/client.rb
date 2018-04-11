require 'net/https'
require "openssl"
require 'json'

module BF
  # https://lightning.bitflyer.jp/docs?lang=ja#http-public-api
  class Client
    class BaseRequest
      def  initialize(path: nil)
        path =
          if defined?(Rails)
            File.join(Rails.root, 'bf_config.yaml')
          else
            'bf_config.yaml'
          end
        @config = YAML.load(File.open(path))
      end

      def api_key
        @config['api_key']
      end

      def api_secret
        @config['api_secret']
      end

      def timestamp
        @timestamp ||= Time.now.to_i.to_s
      end

      def http_method
        :POST
      end

      def uri
        @uri ||= URI.parse("https://#{END_POINT}")
      end

      def run(path: , http_class: , query: nil)
        default_body = {
          product_code: PROCUT_CODE,
          child_order_type: 'LIMIT',
        }
        body = yield(default_body) if block_given?
        uri.path = path
        uri.query = query if query
        text = [timestamp, http_method, uri.request_uri, body].join
        sign = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), api_secret, text)
        options = http_class.new(uri.request_uri, initheader = {
          "ACCESS-KEY" => api_key,
          "ACCESS-TIMESTAMP" => timestamp,
          "ACCESS-SIGN" => sign,
          "Content-Type" => "application/json",
        })
        options.body = body if block_given?
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        response = https.request(options)
        BF.logger.info [text, response.body].inspect
        if response.body.empty?
          return response.code
        else
          res = JSON.parse(response.body)
          if res.is_a?(Array) # for get order
            return res
          end
          if res['child_order_acceptance_id'] # for new order
            return res['child_order_acceptance_id']
          end
          if res['error_message'] # for new order
            raise(res['error_message'])
          end
        end
      end
    end

    class BuyRequest < BaseRequest
      def run(price, size)
        super(path: '/v1/me/sendchildorder', http_class: Net::HTTP::Post) do |body|
          body.merge(price: price, size: size, side: 'BUY').to_json
        end
      end
    end

    class SellRequest < BaseRequest
      def run(price, size)
        super(path: '/v1/me/sendchildorder', http_class: Net::HTTP::Post) do |body|
          body.merge(price: price, size: size, side: 'SELL').to_json
        end
      end
    end

    class CancelRequest < BaseRequest
      def run(order_id)
        super(path: '/v1/me/cancelchildorder', http_class: Net::HTTP::Post) do |body|
          body.merge(child_order_acceptance_id: order_id).to_json
        end
      end
    end

    class GetOrderRequest < BaseRequest
      # order status
      # => 'ACTIVE', 'COMPLETED', 'CANCELED', 'EXPIRED', 'REJECTED'
      def run(order_id)
        return if order_id.nil?
        response = super(path: "/v1/me/getchildorders",
                         http_class: Net::HTTP::Get,
                         query: "product_code=#{PROCUT_CODE}&child_order_acceptance_id=#{order_id}")
        order = response.first
        order['child_order_state'] if order.present?
      end

      def http_method
        :GET
      end
    end

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
      rescue OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, SocketError => e
        sleep(5)
        retry
      rescue Timeout::Error
        sleep(5)
        retry
      end
      JSON.parse(body)
    end

    def buy(price, size)
      BuyRequest.new.run(price, size)
    end

    def sell(price, size)
      SellRequest.new.run(price, size)
    end

    def get_order(order_id)
      GetOrderRequest.new.run(order_id)
    end

    def cancel_order(order_id)
      CancelRequest.new.run(order_id)
    end
  end
end
