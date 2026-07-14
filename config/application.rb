require_relative 'boot'

# Only load the frameworks we actually use.
# Skip: ActionCable (websockets), ActiveStorage (file uploads),
# ActionMailbox, ActionText.
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
# require 'action_cable/engine'   # uncomment for websockets
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)

module PulseDesk
  class Application < Rails::Application
    config.load_defaults 7.1

    # ActiveJob adapter (overridden in env-specific files):
    #   development: :async   (in-process worker thread, no Redis required)
    #   test:        :test   (synchronous, for RSpec)
    #   production:  :sidekiq (set in environments/production.rb once Redis is provisioned)
    config.active_job.queue_adapter = :async

    # Time zone
    config.time_zone = 'UTC'

    # Generators: RSpec (no fixtures, use FactoryBot)
    config.generators do |g|
      g.test_framework :rspec, fixtures: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    # Force SSL in production
    config.force_ssl = false
  end
end
