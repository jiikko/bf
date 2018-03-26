module BF
  class Fetcher
    def run
      loop do
        BF::Trade.fetch_with_clean
        sleep(2)
      end
    end
  end
end
