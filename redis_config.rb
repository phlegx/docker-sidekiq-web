# frozen_string_literal: true

# Redis Config
#
# Description: Redis configuration with sentinel configuration options.
# Author: Egon Zemmer, Phlegx Systems OG
require 'redis-namespace'

module RedisConfig
  class << self
    def config(options = {})
      if ENV['REDIS_SENTINEL_URIS'].nil?
        single_config(options)
      else
        sentinel_config(options)
      end
    end

    private

    def single_config(options = {})
      namespace = options.delete(:namespace)
      uri = "#{ENV['REDIS_URI']}/#{options.delete(:db).to_i}"
      redis = Redis.new(
        driver:   ENV.fetch('REDIS_DRIVER', :hiredis).to_sym,
        url:      "redis://#{uri}",
        password: ENV['REDIS_PASSWORD'],
        **options
      )
      namespace ? Redis::Namespace.new(namespace, redis: redis) : redis
    end

    def sentinel_config(options = {})
      sentinels = ENV['REDIS_SENTINEL_URIS'].split(',').map do |url|
        index = url.rindex(%r{:\d+(/\d*)?$})
        port = index ? url[index + 1, url.length - 1].partition('/').first.strip : ENV['REDIS_SENTINEL_PORT'].to_i
        host = index ? url[0, index] : url
        { host: host.strip, port: port, password: ENV['REDIS_SENTINEL_PASSWORD'] }
      end

      namespace = options.delete(:namespace)
      redis = Redis.new(
        driver:    ENV.fetch('REDIS_DRIVER', :hiredis).to_sym,
        url:       "redis://#{ENV['REDIS_SENTINEL_MASTER_URI']}",
        sentinels: sentinels,
        password:  ENV['REDIS_SENTINEL_PASSWORD'],
        role:      :master,
        **options
      )
      namespace ? Redis::Namespace.new(namespace, redis: redis) : redis
    end
  end
end
