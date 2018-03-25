require 'net/https'
require 'json'

module BfTools
  END_POINT = 'api.bitflyer.jp'

  class Client
    class << self
      def get_health
        JSON.parse(self.new.get('/v1/gethealth'))
      end
    end

    def get(path)
      https = Net::HTTP.new(END_POINT, 443)
      https.use_ssl = true
      https.start { |https| response = https.get(path) }.body
    end
  end
end
