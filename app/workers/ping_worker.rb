# frozen_string_literal: true

require 'timeout'

require_relative '../models/ip'
require_relative '../models/ping'

class PingWorker
  include Sidekiq::Worker

  PingError = Class.new(StandardError)

  TIMEOUT = 1

  def perform(id)
    ip = ::Ip.find(id:)
    output = Timeout.timeout(TIMEOUT) { `ping -c 1 #{ip.address}` }

    raise PingError, 'Ping unreachable' unless $?.success?

    ::Ping.create(ip:, rtt: rtt(output), success: true)
  rescue Timeout::Error, PingError => e
    ::Ping.create(ip:, error_message: e.message)
  end

  private

  def rtt(output)
    output.match(/time=([\d.]+)\s*ms/)[1]
  end
end
