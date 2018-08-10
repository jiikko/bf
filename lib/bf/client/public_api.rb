module BF
  class Client
    class PublicApi
      def get_public_api(path, product_code)
        pt = "#{path}?PRODUCT_CODE=#{product_code}"
        host = URI.parse(END_POINT)
        https = Net::HTTP.new(host.host, 443)
        https.use_ssl = true
        body = https.start { |https| response = https.get(pt) }.body
        JSON.parse(body)
      end
    end
  end
end
