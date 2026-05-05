# frozen_string_literal: true

require 'yaml'
require 'sequel'

if (database_url = ENV['DATABASE_URL'])
  DB = Sequel.connect(database_url)
else
  db_config = YAML.load_file('config/database.yml')
  env = ENV['RACK_ENV'] || 'development'
  config = db_config[env]

  DB = Sequel.connect(config)
end
