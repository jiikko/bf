ENV['RUN_ENV'] ||= 'resque'

require "bundler/setup"
require 'bf'

Resque.redis.namespace = "resque:bf"
Resque.logger = Logger.new('log/rescue.log')
Resque.logger.level = Logger::INFO

if (defined?(Rails).nil?) && (ENV['RUN_ENV'] == 'resque')
  BF::CLI.new.db_connect!
end
