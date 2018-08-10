# rake bf:fetcher:run

namespace :bf do
  namespace :fetcher do
    desc "run fetcher process"
    task :run do
      require 'bf'
      puts 'start fetcher process'
      unless defined?(Rails)
        cli = BF::CLI.new
        cli.db_connect!
      end
      BF::Fetcher.new.run
    end
  end
end
