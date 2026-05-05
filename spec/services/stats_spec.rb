# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::Stats do
  describe '.validate' do
    it 'returns parsed times on success' do
      time_from = Time.now - 3600
      time_to = Time.now

      result = described_class.validate(
        'time_from' => time_from.iso8601,
        'time_to' => time_to.iso8601
      )

      expect(result[:time_from]).to be_a(Time)
      expect(result[:time_to]).to be_a(Time)
      expect(result[:errors]).to be_nil
    end

    it 'returns errors on failure' do
      result = described_class.validate('time_from' => 'invalid', 'time_to' => '')

      expect(result[:errors]).to be_a(Hash)
      expect(result[:errors]).not_to be_empty
    end
  end

  describe '.calculate' do
    let(:ip) { Ip.create(address: '10.0.0.1') }
    let(:time_from) { Time.now - 3600 }
    let(:time_to) { Time.now }

    context 'with successful pings' do
      before do
        5.times do |i|
          Ping.create(
            ip_id: ip.id,
            rtt: 10.0 + i,
            success: true,
            created_at: Time.now - 1800
          )
        end
      end

      it 'returns stats hash' do
        result = described_class.calculate(ip, time_from, time_to)

        expect(result[:total_pings]).to eq(5)
        expect(result[:successful_pings]).to eq(5)
        expect(result[:failed_pings]).to eq(0)
        expect(result[:avg_rtt]).to be_a(BigDecimal)
        expect(result[:min_rtt]).to be_a(BigDecimal)
        expect(result[:max_rtt]).to be_a(BigDecimal)
        expect(result[:median_rtt]).to be_a(BigDecimal)
        expect(result[:packet_loss_percent]).to eq(0)
      end
    end

    context 'with failed pings' do
      before do
        3.times do
          Ping.create(
            ip_id: ip.id,
            success: false,
            error_message: 'Ping unreachable',
            created_at: Time.now - 1800
          )
        end
      end

      it 'calculates packet loss' do
        result = described_class.calculate(ip, time_from, time_to)

        expect(result[:total_pings]).to eq(3)
        expect(result[:successful_pings]).to eq(0)
        expect(result[:failed_pings]).to eq(3)
        expect(result[:packet_loss_percent]).to eq(100.0)
      end
    end

    context 'with mixed pings' do
      before do
        7.times do |i|
          Ping.create(
            ip_id: ip.id,
            rtt: 10.0 + i,
            success: true,
            created_at: Time.now - 1800
          )
        end

        3.times do
          Ping.create(
            ip_id: ip.id,
            success: false,
            error_message: 'Ping unreachable',
            created_at: Time.now - 1800
          )
        end
      end

      it 'calculates correct statistics' do
        result = described_class.calculate(ip, time_from, time_to)

        expect(result[:total_pings]).to eq(10)
        expect(result[:successful_pings]).to eq(7)
        expect(result[:failed_pings]).to eq(3)
        expect(result[:packet_loss_percent]).to eq(30.0)
      end

      it 'calculates RTT statistics correctly' do
        result = described_class.calculate(ip, time_from, time_to)

        expect(result[:avg_rtt]).to eq(13.0)
        expect(result[:min_rtt]).to eq(10.0)
        expect(result[:max_rtt]).to eq(16.0)
        expect(result[:median_rtt]).to eq(13.0)
      end
    end

    context 'without ping data' do
      it 'returns error message' do
        result = described_class.calculate(ip, time_from, time_to)
        expect(result[:error]).to eq("No ping data available for this period")
      end
    end

    context 'with time filtering' do
      it 'only includes pings within time range' do
        Ping.create(
          ip_id: ip.id,
          rtt: 5.0,
          success: true,
          created_at: time_from - 3600 # вне диапазона
        )

        result = described_class.calculate(ip, time_from, time_to)
        expect(result[:error]).to eq("No ping data available for this period")
      end

      it 'includes pings at boundaries' do
        Ping.create(
          ip_id: ip.id,
          rtt: 10.0,
          success: true,
          created_at: time_from
        )

        Ping.create(
          ip_id: ip.id,
          rtt: 20.0,
          success: true,
          created_at: time_to
        )

        result = described_class.calculate(ip, time_from, time_to)
        expect(result[:total_pings]).to eq(2)
        expect(result[:min_rtt]).to eq(10.0)
        expect(result[:max_rtt]).to eq(20.0)
      end
    end

    context 'with multiple IPs' do
      it 'calculates stats only for specified IP' do
        ip2 = Ip.create(address: '10.0.0.2')

        Ping.create(ip_id: ip.id, rtt: 10.0, success: true, created_at: Time.now - 1000)
        Ping.create(ip_id: ip2.id, rtt: 20.0, success: true, created_at: Time.now - 1000)

        result = described_class.calculate(ip, time_from, time_to)
        expect(result[:total_pings]).to eq(1)
        expect(result[:avg_rtt]).to eq(10.0)
      end
    end
  end
end
