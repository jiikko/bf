module BF
  class Client
    class PublicApi
      def get_public_api(path, product_code)
        pt = "#{path}?PRODUCT_CODE=#{product_code}"
        uri = URI.parse(END_POINT)
        https = Net::HTTP.new(uri.host, 443)
        https.use_ssl = true
        response =
          Timeout.timeout(2) do
            https.start { |https| response = https.get(pt) }
          end
        BF::ApiCallLog.create!(api_type: :public_api,
                               request_body: "GET: #{uri.request_uri}",
                               response_code: response.code,
                               response_body: response.body[0..100])
        JSON.parse(response.body)
      rescue => e
        BF::ApiCallLog.create!(api_type: :public_api,
                              request_body: "GET: #{uri.request_uri}",
                              error_trace:  [e.inspect + e.full_message].join("\n"),
                              response_code: response&.code,
                              response_body: (response&.body && response&.body[0..100]))
        raise
      end
    end
  end
end
