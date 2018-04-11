module BF
  class CLI
    def self.run
      ENV['RUN_ENV'] = 'cli'
      cli = new
      cli.db_connect!
      cli.start
    end

    def start
      loop do
        BF::Setting
        puts BF::Monitor.new.current_ranges
        BF::Trade.fetch_with_clean
        sleep(2)
      end
    end

    def db_connect!
      database_yml = File.expand_path('../../../database.yml', __FILE__)
      ActiveRecord::Base.configurations = YAML.load_file(database_yml)
      ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), '../../log/test.log'))
      ActiveRecord::Base.establish_connection(:mysql)
      unless ENV['RUN_ENV'] == 'resque'
        ActiveRecord::Migrator.migrate(File.expand_path('../../../db/migrate', __FILE__))
      end
    end
  end
end
