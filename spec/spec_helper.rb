# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'roda'
require 'rack/test'
require 'rspec'
require 'database_cleaner-sequel'
require 'webmock/rspec'

require_relative '../config/database'
require_relative '../config/environment'

Dir[File.join(__dir__, '..', 'app', '**', '*.rb')].sort.each { |f| require f }
require_relative '../app'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:suite) do
    DatabaseCleaner[:sequel].db = DB
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning { example.run }
  end

  def app
    App.freeze.app
  end

  def json_response
    JSON.parse(last_response.body)
  end
end
