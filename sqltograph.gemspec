# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqltograph/version'

Gem::Specification.new do |spec|
  spec.name          = "sqltograph"
  spec.version       = Sqltograph::VERSION
  spec.authors       = ["Javad Karabi"]
  spec.email         = ["karabijavad@gmail.com"]
  spec.summary       = %q{create a graph database from your current relational database.}
  spec.description   = %q{create a graph database from your current relational database.}
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.platform = 'java'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "database_cleaner"
  spec.add_dependency "dotenv"
  spec.add_dependency "cadet"
  spec.add_dependency "activerecord"
  spec.add_dependency "activerecord-jdbcmysql-adapter"
  spec.add_dependency "jdbc-postgres"
end
