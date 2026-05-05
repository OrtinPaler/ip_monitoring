# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :ips do
      primary_key :id
      column :address, :varchar, null: false
      column :enabled, :boolean, default: false, null: false
      column :created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP, null: false
      column :updated_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP, null: false

      index :address, unique: true
    end
  end
end
