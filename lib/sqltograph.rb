require "sqltograph/version"

require 'dotenv'

Dotenv.load "#{ENV['APP_ENV'] || 'development'}.env"

module Sqltograph
end
