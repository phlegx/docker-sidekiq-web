# frozen_string_literal: true

# Redis Config
#
# Description: Rackup to get Sidekiq Web running with session cookie and HTTP basic auth.
# Author: Egon Zemmer, Phlegx Systems OG
require 'securerandom'
require 'rack'
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

# Create Redis instance.
redis = proc {
  RedisConfig.config(
    db: ENV['REDIS_DB'].to_i,
    namespace: ENV['REDIS_NAMESPACE']
  )
}

# Configure Sidekiq client with Redis instance.
Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(
    size: ENV['REDIS_POOL_SIZE'].nil? ? 1 : ENV['REDIS_POOL_SIZE'].to_i,
    &redis
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
