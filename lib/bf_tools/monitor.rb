module BfTools
  class Monitor
    def ranges
      [1..2, 1..3, 2..5]
    end

    def current_health
      BfTools::Client.get_health
    end
  end
end
