# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :pings do
      primary_key :id
      foreign_key :ip_id, :ips, null: false, on_delete: :cascade
      column :rtt, :float
      column :success, :boolean, null: false, default: false
      column :error_message, :varchar
      column :created_at, :timestamp, default: Sequel::CURRENT_TIMESTAMP, null: false

      index :ip_id
      index :created_at
      index [:ip_id, :created_at]
    end
  end
end