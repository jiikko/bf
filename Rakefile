require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'resque/tasks'
require 'bf'

import "./lib/tasks/bf_fetcher.rake"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
