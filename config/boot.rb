ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup'
require 'dotenv/load' if ENV['RAILS_ENV'] != 'production' && File.exist?(File.expand_path('../.env', __dir__))
