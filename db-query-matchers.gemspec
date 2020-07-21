# coding: utf-8
$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'db_query_matchers/version'

Gem::Specification.new do |spec|
  spec.name          = 'db-query-matchers'
  spec.version       = DBQueryMatchers::VERSION
  spec.authors       = ['Brigade Engineering', 'Henric Trotzig', 'Joe Lencioni']
  spec.email         = ['eng@brigade.com', 'henric.trotzig@brigade.com',
                        'joe.lencioni@brigade.com']
  spec.summary       = 'RSpec matchers for database queries'
  spec.homepage      = 'https://github.com/brigade/db-query-matchers'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '>= 4.0', "< 7"
  spec.add_runtime_dependency 'rspec', '>= 3.0'

  spec.add_development_dependency 'activerecord',  '>= 4.0', "< 7"
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency "appraisal", "~> 2.0"

  spec.required_ruby_version = ">= 1.9.2"
end
