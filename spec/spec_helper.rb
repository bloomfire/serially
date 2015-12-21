require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'resque'
require 'mock_redis'
require 'pry'
require 'database_cleaner'
require 'serially'
#require 'resque-lonely_job'
#require 'timecop'

RSpec.configure do |config|
  config.before(:suite) do
    Resque.redis = MockRedis.new
  end

  # clean Resque before every top-level group
  config.before(:all) do
    Resque.redis.flushdb
  end

  # should syntax is more readable
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
  config.mock_with :rspec do |c|
    c.syntax = :should
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    DatabaseCleaner.clean
  end

end

# example model classes
Dir[File.dirname(__FILE__) + "/models/*.rb"].sort.each { |f| require File.expand_path(f) }