# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ip do
  describe 'validations' do
    it 'validates presence of address' do
      ip = Ip.new(enabled: false)
      expect(ip).not_to be_valid
      expect(ip.errors[:address]).to include('is not present')
    end

    it 'validates uniqueness of address' do
      Ip.create(address: '192.168.1.1', enabled: false)
      ip = Ip.new(address: '192.168.1.1', enabled: false)
      expect(ip).not_to be_valid
      expect(ip.errors[:address]).to include('is already taken')
    end

    it 'validates IP format' do
      ip = Ip.new(address: 'invalid', enabled: false)
      expect(ip).not_to be_valid
      expect(ip.errors[:ip_address]).to include('is not a valid IPv4 or IPv6 address')
    end

    it 'accepts valid IPv4' do
      ip = Ip.create(address: '192.168.1.1', enabled: false)
      expect(ip).to be_valid
    end

    it 'accepts valid IPv6' do
      ip = Ip.create(address: '2001:db8::1', enabled: false)
      expect(ip).to be_valid
    end
  end

  describe 'defaults' do
    it 'sets enabled to false by default' do
      ip = Ip.create(address: '10.0.0.1')
      expect(ip.enabled).to be false
    end
  end

  describe '#to_hash' do
    it 'returns hash with correct format' do
      ip = Ip.create(address: '10.0.0.1')
      hash = ip.to_hash

      expect(hash).to include(
                        id: ip.id,
                        address: '10.0.0.1',
                        enabled: false
                      )
      expect(hash[:created_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(hash[:updated_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end

  describe 'associations' do
    it 'has many pings' do
      ip = Ip.create(address: '10.0.0.1')
      ping1 = Ping.create(ip: ip, success: true)
      ping2 = Ping.create(ip: ip, success: false)

      expect(ip.pings).to contain_exactly(ping1, ping2)
    end

    it 'destroys pings when IP is deleted' do
      ip = Ip.create(address: '10.0.0.1')
      Ping.create(ip: ip, success: true)
      Ping.create(ip: ip, success: false)

      expect { ip.destroy }.to change(Ping, :count).by(-2)
    end
  end
end
