# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::Ip do
  describe '.create' do
    let(:valid_params) { { 'ip' => '192.168.1.100', 'enabled' => true } }

    it 'creates IP record' do
      expect {
        described_class.create(valid_params)
      }.to change { ::Ip.count }.by(1)
    end

    it 'returns hash with correct attributes' do
      result = described_class.create(valid_params)

      expect(result).to be_a(Hash)
      expect(result[:address]).to eq('192.168.1.100')
      expect(result[:enabled]).to be true
      expect(result[:id]).to be_a(Integer)
      expect(result[:created_at]).to be_a(String)
      expect(result[:updated_at]).to be_a(String)
    end

    it 'creates IP with enabled false' do
      result = described_class.create('ip' => '10.0.0.1', 'enabled' => false)
      expect(result[:enabled]).to be false
    end

    context 'with invalid params' do
      it 'raises error for invalid IP' do
        expect {
          described_class.create('ip' => 'invalid', 'enabled' => true)
        }.to raise_error(AppError, /ip_address is not a valid IPv4 or IPv6 address/)
      end

      it 'raises error for duplicate IP' do
        ::Ip.create(address: '192.168.1.100', enabled: false)

        expect {
          described_class.create(valid_params)
        }.to raise_error(AppError, /address is already taken/)
      end

      it 'raises error for missing IP' do
        expect {
          described_class.create('enabled' => true)
        }.to raise_error(AppError, /address is not present/)
      end
    end
  end

  describe '.enable' do
    it 'enables disabled IP' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: false)
      described_class.enable(ip)

      expect(ip.reload.enabled).to be true
    end

    it 'does nothing if already enabled' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: true)
      original_updated_at = ip.updated_at

      described_class.enable(ip)

      expect(ip.reload.enabled).to be true
      expect(ip.updated_at).to eq(original_updated_at)
    end
  end

  describe '.disable' do
    it 'disables enabled IP' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: true)
      described_class.disable(ip)

      expect(ip.reload.enabled).to be false
    end

    it 'does nothing if already disabled' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: false)
      original_updated_at = ip.updated_at

      described_class.disable(ip)

      expect(ip.reload.enabled).to be false
      expect(ip.updated_at).to eq(original_updated_at)
    end
  end

  describe '.delete' do
    it 'deletes IP record' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: false)

      expect {
        described_class.delete(ip)
      }.to change { ::Ip.count }.by(-1)
    end

    it 'deletes associated pings' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: false)
      Ping.create(ip_id: ip.id, success: true)
      Ping.create(ip_id: ip.id, success: false)

      expect {
        described_class.delete(ip)
      }.to change { Ping.count }.by(-2)
    end

    it 'disables IP before deletion if enabled' do
      ip = ::Ip.create(address: '10.0.0.1', enabled: true)

      described_class.delete(ip)

      expect(::Ip.find(id: ip.id)).to be_nil
    end
  end
end
