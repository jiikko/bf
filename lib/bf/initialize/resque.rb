ENV['RUN_ENV'] ||= 'resque'

require "bundler/setup"
require 'bf'

Resque.redis.namespace =
  if ENV['RUN_ENV'] == 'test'
    "resque:bf:test"
  else
    "resque:bf"
  end

Resque.logger = Logger.new('log/rescue.log', 4)
Resque.logger.level = Logger::INFO

if (defined?(Rails).nil?) && (ENV['RUN_ENV'] == 'resque')
  BF::CLI.new.db_connect!
end
