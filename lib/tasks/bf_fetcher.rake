# rake bf:fetcher:run

namespace :bf do
  namespace :fetcher do
    desc "run fetcher process"
    task :run do
      require 'bf'
      puts 'start fetcher process'
      unless defined?(Rails)
        cli = BF::CLI.new
        cli.connect!
      end
      BF::Fetcher.new.run
    end
  end

  namespace :status_fetcher do
    desc "run status fetcher process"
    task :run do
      require 'bf'
      puts 'start status fetcher process'
      unless defined?(Rails)
        cli = BF::CLI.new
        cli.connect!
      end
      BF::StatusFetcher.new.run
    end
  end
end
