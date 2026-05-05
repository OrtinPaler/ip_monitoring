# frozen_string_literal: true

require_relative 'config/database'

namespace :db do
  desc 'Run migrations'
  task :migrate do
    require 'sequel/core'
    Sequel.extension :migration
    Sequel::Migrator.run(DB, 'db/migrate')
    puts 'Migrations completed successfully'
  end
end
