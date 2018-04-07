ENV['RUN_ENV'] = 'resque'

require "bundler/setup"
require 'bf'

Resque.redis.namespace = "resque:bf"
Resque.logger = Logger.new('rescue.log')
Resque.logger.level = Logger::INFO

unless defined?(Rails)
  BF::CLI.new.db_connect!
end
