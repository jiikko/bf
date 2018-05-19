module BF
  class Client
    class PublicApi
      def get_public_api(path, product_code)
        pt = "#{path}?PRODUCT_CODE=#{product_code}"
        https = Net::HTTP.new(END_POINT, 443)
        https.use_ssl = true
        body = nil
        body = https.start { |https| response = https.get(pt) }.body
        JSON.parse(body)
      end
    end
  end
end
