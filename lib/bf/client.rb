require 'net/https'
require "openssl"
require 'json'
require 'bf/client/public_api'
require 'bf/client/private_api'

# https://lightning.bitflyer.jp/docs?lang=ja#http-public-api
module BF
  class Client
    def buy(price, size)
      disparity = BF::Monitor.new.current_disparity_from_datastore
      if disparity >= BF::STOP_DISPARITY_LIMIT
        raise(BF::DisparityOverError)
      end

      BuyRequest.new.run(price, size)
    end

    def sell(price, size)
      SellRequest.new.run(price, size)
    end

    def get_order(order_id: nil, order_acceptance_id: nil)
      retry_with do
        GetOrderRequest.new.run(order_id: order_id, order_acceptance_id: order_acceptance_id)
      end
    end

    def cancel_order(order_acceptance_id)
      retry_with do
        CancelRequest.new.run(order_acceptance_id)
      end
    end

    def get_state
      retry_with do
        PublicApi.new.get_public_api("/v1/getboardstate", BTC_FX_PRODUCT_CODE) || {}
      end
    end

    def get_disparity
      fx =
        retry_with do
          (PublicApi.new.get_public_api("/v1/getboard", BTC_FX_PRODUCT_CODE) || {})['mid_price']
        end
      btc =
        retry_with do
          (PublicApi.new.get_public_api("/v1/getboard", BTC_PRODUCT_CODE) || {})['mid_price']
        end
      (fx / btc) * 100 - 100
    end

    def get_ticker
      retry_with do
        PublicApi.new.get_public_api("/v1/ticker", BTC_FX_PRODUCT_CODE) || {}
      end
    end

    private

    # postだと二重注文になる可能性があるので注文では使わない
    def retry_with
      begin
        return yield
      rescue RuntimeError => e
        BF.logger.info e.inspect
      rescue OpenSSL::SSL::SSLError,
          Net::HTTPBadResponse,
          Errno::ECONNRESET,
          Errno::ECONNREFUSED,
          Errno::ETIMEDOUT,
          Errno::EHOSTUNREACH,
          SocketError => e
        BF.logger.info e.inspect
        sleep(3)
        retry
      rescue JSON::ParserError
        sleep(3)
        retry # メンテナンス中だとHTMLが返ってきてparseが失敗するので
      rescue Timeout::Error, Net::OpenTimeout => e
        BF.logger.info e.inspect
        sleep(5)
        retry
      end
    end
  end
end
