# frozen_string_literal: true

require 'ipaddr'

class Ip < Sequel::Model
  one_to_many :pings

  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def before_validation
    self.enabled ||= false
    super
  end

  def validate
    super
    validates_presence :address
    validates_unique :address
    validates_format_address if address
    validates_includes [true, false], :enabled
  end

  def to_hash
    {
      id:,
      address:,
      enabled:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end

  private

  def validates_format_address
    IPAddr.new(address)
  rescue IPAddr::InvalidAddressError
    errors.add(:ip_address, 'is not a valid IPv4 or IPv6 address')
  end
end
