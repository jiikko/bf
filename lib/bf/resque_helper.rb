module BF
  module ResqueHelper
    class << self
      def queueing?(name='normal', jobname, args)
        # TODO
      end

      def jobs
        # or Resque.peek('normal', 0, 100)
        Resque.redis.lrange('queue:normal', 0, 50)
      end

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
