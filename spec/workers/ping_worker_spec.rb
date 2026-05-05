# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PingWorker do
  describe '#perform' do
    let(:ip) { Ip.create(address: '8.8.8.8') }

    context 'successful ping' do
      before do
        allow_any_instance_of(described_class).to receive(:`).and_return(
          "64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=12.5 ms\n"
        )
        allow($?).to receive(:success?).and_return(true)
      end

      it 'creates successful ping record' do
        expect {
          subject.perform(ip.id)
        }.to change { Ping.count }.by(1)

        ping = Ping.last
        expect(ping.success).to be true
        expect(ping.rtt).to eq(12.5)
        expect(ping.ip_id).to eq(ip.id)
        expect(ping.error_message).to be_nil
      end

      it 'extracts RTT correctly with decimal' do
        allow_any_instance_of(described_class).to receive(:`).and_return(
          "64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=0.5 ms\n"
        )
        allow($?).to receive(:success?).and_return(true)

        subject.perform(ip.id)
        expect(Ping.last.rtt).to eq(0.5)
      end

      it 'extracts RTT with multiple digits' do
        allow_any_instance_of(described_class).to receive(:`).and_return(
          "64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=100.123 ms\n"
        )
        allow($?).to receive(:success?).and_return(true)

        subject.perform(ip.id)
        expect(Ping.last.rtt).to eq(100.123)
      end
    end

    context 'failed ping' do
      before do
        allow_any_instance_of(described_class).to receive(:`).and_return("")
        allow($?).to receive(:success?).and_return(false)
      end

      it 'creates failed ping record' do
        expect {
          subject.perform(ip.id)
        }.to change { Ping.count }.by(1)

        ping = Ping.last
        expect(ping.success).to be false
        expect(ping.rtt).to be_nil
        expect(ping.error_message).to eq('Ping unreachable')
      end
    end

    context 'timeout' do
      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error, 'execution expired')
      end

      it 'creates failed ping with timeout error' do
        expect {
          subject.perform(ip.id)
        }.to change { Ping.count }.by(1)

        ping = Ping.last
        expect(ping.success).to be false
        expect(ping.rtt).to be_nil
        expect(ping.error_message).to eq('execution expired')
      end
    end

    context 'ping unreachable' do
      before do
        allow_any_instance_of(described_class).to receive(:`).and_return(
          "ping: cannot resolve 8.8.8.8: Unknown host\n"
        )
        allow($?).to receive(:success?).and_return(false)
      end

      it 'creates failed ping' do
        subject.perform(ip.id)

        ping = Ping.last
        expect(ping.success).to be false
        expect(ping.error_message).to eq('Ping unreachable')
      end
    end
  end
end
