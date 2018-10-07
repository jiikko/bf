# rake bf:daemon:run

namespace :bf do
  namespace :daemon do
    desc "run daemon process"
    task :run do
      require 'bf'
      puts 'start daemon process'
      unless defined?(Rails)
        cli = BF::CLI.new
        cli.db_connect!
      end
      BF::Daemon.new.run
    end
  end
end
