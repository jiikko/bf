module BF
  module ResqueHelper
    class << self
      def clear_jobs
        result = []
        4.times do
          result << Resque.redis.lrange('queue:normal', 0, 50).map do |x|
            Resque::Job.destroy('normal', *eval(x).values.first)
          end
        end
        result.flatten
      end
    end
  end
end
