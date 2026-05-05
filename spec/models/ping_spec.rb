# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ping do
  describe 'associations' do
    it 'belongs to ip' do
      ip = Ip.create(address: '10.0.0.1')
      ping = Ping.create(ip_id: ip.id, success: true)

      expect(ping.ip).to eq(ip)
    end
  end

  describe 'creation' do
    let(:ip) { Ip.create(address: '192.168.1.1') }

    it 'creates successful ping' do
      ping = Ping.create(ip_id: ip.id, success: true, rtt: 12.5)

      expect(ping.valid?).to be true
      expect(ping.rtt).to eq(12.5)
      expect(ping.success).to be true
      expect(ping.error_message).to be_nil
    end

    it 'creates failed ping' do
      ping = Ping.create(ip_id: ip.id, success: false, error_message: 'Ping unreachable')

      expect(ping.valid?).to be true
      expect(ping.success).to be false
      expect(ping.rtt).to be_nil
      expect(ping.error_message).to eq('Ping unreachable')
    end

    it 'creates timeout ping' do
      ping = Ping.create(
        ip_id: ip.id,
        success: false,
        error_message: 'Timeout: execution expired'
      )

      expect(ping.success).to be false
      expect(ping.error_message).to include('Timeout')
    end
  end

  describe 'defaults' do
    let(:ip) { Ip.create(address: '192.168.1.1') }

    it 'sets success to false by default' do
      ping = Ping.create(ip_id: ip.id)
      expect(ping.success).to be false
    end

    it 'sets created_at' do
      ping = Ping.create(ip_id: ip.id)
      expect(ping.created_at).not_to be_nil
      expect(ping.created_at).to be_a(Time)
    end
  end
end
