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

    def get_order(order_acceptance_id: nil)
      retry_with(from: :get_order) do
        GetOrderRequest.new.run(order_acceptance_id: order_acceptance_id)
      end
    end

    def cancel_order(order_acceptance_id)
      retry_with(from: :cancel_order) do
        CancelRequest.new.run(order_acceptance_id)
      end
    end

    def preorders
      retry_with(from: :preorders) do
        GetPreorderListRequest.new.run
      end
    end

    def get_state
      retry_with(from: :get_state) do
        PublicApi.new.get_public_api("/v1/getboardstate", BTC_FX_PRODUCT_CODE) || {}
      end
    end

    def get_disparity
      fx =
        retry_with(from: :get_disparity_fx) do
          (PublicApi.new.get_public_api("/v1/getboard", BTC_FX_PRODUCT_CODE) || {})['mid_price']
        end
      btc =
        retry_with(from: :get_disparity) do
          (PublicApi.new.get_public_api("/v1/getboard", BTC_PRODUCT_CODE) || {})['mid_price']
        end
      (fx || (return(100))) && (btc || (return(100)))
      (fx / btc) * 100 - 100
    end

    def get_ticker
      retry_with(from: :get_ticker) do
        PublicApi.new.get_public_api("/v1/ticker", BTC_FX_PRODUCT_CODE) || {}
      end
    end

    private

    # postだと二重注文になる可能性があるので注文では使わない
    def retry_with(from: nil)
      retry_count = 0
      begin
        return yield
      rescue OpenSSL::SSL::SSLError,
          Net::HTTPBadResponse,
          Errno::ECONNRESET,
          Errno::ECONNREFUSED,
          Errno::ETIMEDOUT,
          Errno::EHOSTUNREACH,
          SocketError => e
        BF.logger.error("[#{from}]" + e.inspect + e.full_message)
        sleep(2)
        retry
      rescue JSON::ParserError
        sleep(3)
        retry # メンテナンス中だとHTMLが返ってきてparseが失敗するので
      rescue Timeout::Error => e
        BF.logger.error("[#{from}]" + e.inspect + e.full_message)
        sleep(sleep_count_when_timeout)
        retry_count += 1
        if retry_count < 5
          BF.logger.info("[#{from}]" + 'retry!')
          retry
        else
          {}
        end
      rescue RuntimeError => e
        BF.logger.error("[#{from}]" + e.inspect + e.full_message)
        false
      rescue => e
        BF.logger.error("[#{from}]" + e.inspect + e.full_message)
        false
      end
    end

    def sleep_count_when_timeout
      2
    end
  end
end
