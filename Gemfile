source 'https://rubygems.org'

# Core
gem 'bootsnap', '~> 1.18', require: false
gem 'puma', '~> 6.4'
gem 'rails', '~> 7.1.3'
gem 'sqlite3', '~> 1.7'

# Frontend
gem 'sprockets-rails'
gem 'tailwindcss-rails', '~> 2.3'

# Background jobs / Redis (use async adapter if no Redis available)
gem 'redis', '~> 5.0', require: false
gem 'sidekiq', '~> 7.2', require: false

# HTTP for LLM
gem 'faraday', '~> 2.9'
gem 'faraday-retry', '~> 2.2'

# Config
gem 'dotenv-rails', '~> 3.1'

# Auth (lightweight; uses Rails has_secure_password)
gem 'bcrypt', '~> 3.1.20'

# Charts: rendered with inline HTML progress bars (no JS dependency)

group :development, :test do
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'rspec-rails', '~> 6.1'
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rails', '~> 2.23', require: false
  gem 'rubocop-rspec', '~> 2.26', require: false
end

group :test do
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'shoulda-matchers', '~> 6.2'
  gem 'webmock', '~> 3.23'
end

# Windows needs tzinfo-data to read IANA timezones in some gems
gem 'tzinfo-data', platforms: %i[windows jruby]
