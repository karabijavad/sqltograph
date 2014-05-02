require 'bundler/setup'
Bundler.setup

require 'sqltograph'
require 'active_record'
require 'cadet'
require 'pry'
require 'database_cleaner'

Dotenv.load "test.env"

ActiveRecord::Base.establish_connection ENV["DATABASE_URL"]

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
