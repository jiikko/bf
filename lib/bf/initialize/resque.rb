require "bundler/setup"
require 'bf'

Resque.redis.namespace = "resque:bf"
Resque.logger = Logger.new('rescue.log')
Resque.logger.level = Logger::INFO
