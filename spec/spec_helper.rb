require 'rspec'
require 'pry'
require 'bundler/setup'
Bundler.setup
require 'paging-mister-hyde'

Dir['./spec/support/**/*.rb'].each { |f| require f }