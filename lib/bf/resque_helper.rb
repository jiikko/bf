module BF
  module ResqueHelper
    module Process
      def kill_one(pid)
        pppid = workers.map(&:pid).find { |ppid| ppid == pid.to_i }
        kill(pppid) if pppid.present?
        pppid
      end

      def kill_all
        pids = workers.select { |w| w.job.present? }.map(&:pid)
        pids.each { |pid| kill(pid) }
      end

      private

      def workers
        Resque.workers
      end

      def kill(pid)
        ::Process.kill(:USR1, pid)
      end
    end

    extend Process

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
