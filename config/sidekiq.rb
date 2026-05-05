# frozen_string_literal: true

require_relative 'database'

require 'sidekiq-cron'

Dir['./app/workers/**/*.rb'].sort.each { |f| require f }

redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
