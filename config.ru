# frozen_string_literal: true

# Redis Config
#
# Description: Rackup to get Sidekiq Web running with session cookie and HTTP basic auth.
# Author: Egon Zemmer, Phlegx Systems Technologies GmbH
require 'securerandom'
require 'rack'
require 'rack/session'
require 'hiredis-client'
require 'sidekiq'
require 'sidekiq/web'
if ENV['SIDEKIQ_CRON'] && ENV['SIDEKIQ_CRON'] == 'true'
  require 'sidekiq-cron'
  require 'sidekiq/cron/web'
end
require './redis_config'

# Add Rack session cookie secret.
File.open('.session.key', 'w') { |f| f.write(SecureRandom.hex(32)) }
use Rack::Session::Cookie, secret: File.read('.session.key'), same_site: true, max_age: 86_400

# Ser Redis default driver.
RedisClient.default_driver = ENV.fetch('REDIS_DRIVER', :hiredis).to_sym

# Configure Sidekiq client with Redis instance.
Sidekiq.configure_client do |config|
  config.redis = RedisConfig.config(
    db:   ENV.fetch('REDIS_DB', 0).to_i,
    size: ENV.fetch('REDIS_POOL_SIZE', 5).to_i
  )
end

# Add HTTP Basic Auth to Sidekiq Web.
if ENV['SIDEKIQ_USERNAME'] && ENV['SIDEKIQ_PASSWORD']
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(username),
                               ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_USERNAME'])) &
      Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password),
                                 ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_PASSWORD']))
  end
end

# Run Sidekiq Web.
run Rack::URLMap.new('/' => Sidekiq::Web)
