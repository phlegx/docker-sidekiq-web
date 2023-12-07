# frozen_string_literal: true

# Redis Config
#
# Description: Redis configuration with sentinel configuration options.
# Author: Egon Zemmer, Phlegx Systems Technologies GmbH

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
      {
        url:      "redis://#{ENV['REDIS_URI']}/#{options.delete(:db).to_i}",
        password: ENV['REDIS_PASSWORD'],
        **options
      }
    end

    def sentinel_config(options = {})
      sentinels = ENV['REDIS_SENTINEL_URIS'].split(',').map do |url|
        index = url.rindex(%r{:\d+(/\d*)?$})
        port = index ? url[index + 1, url.length - 1].partition('/').first.strip : ENV['REDIS_SENTINEL_PORT'].to_i
        host = index ? url[0, index] : url
        { host: host.strip, port: port }
      end

      {
        sentinels:         sentinels,
        role:              :master,
        name:              ENV['REDIS_SENTINEL_NAME'],
        sentinel_password: ENV['REDIS_SENTINEL_PASSWORD'],
        password:          ENV['REDIS_PASSWORD'],
        **options
      }
    end
  end
end
