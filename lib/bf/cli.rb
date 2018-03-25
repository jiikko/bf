module BF
  class CLI
    def self.run
      cli = new
      cli.connect!
      cli.start
    end

    def start
      loop do
        puts BF::Monitor.new.current_ranges
        BF::Trade.fetch_with_clean
        sleep(2)
      end
    end

    def connect!
      database_yml = File.expand_path('../../../database.yml', __FILE__)
      ActiveRecord::Base.configurations = YAML.load_file(database_yml)
      ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), '../../debug.log'))
      ActiveRecord::Base.establish_connection(:mysql)
      ActiveRecord::Migrator.migrate(File.expand_path('../../db/migrate', __FILE__))
    end
  end
end
