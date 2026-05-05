# frozen_string_literal: true

require 'sidekiq-cron'

require_relative '../../config/environment'

module Services
  class Ip
    class << self
      def create(params)
        DB.transaction do
          ip = ::Ip.create(address: params['ip'], enabled: params['enabled'])

          Sidekiq::Cron::Job.create(
            name: "ping_ip_#{ip.id}",
            cron: '* * * * *',
            class: 'PingWorker',
            args: [ip.id],
            description: "Ping #{ip.address} every minute"
          )

          ip.to_hash
        rescue StandardError => e
          Sidekiq::Cron::Job.destroy("ping_ip_#{ip.id}") if ip
          raise AppError.new(e.message, 500)
        end
      end

      def enable(ip)
        return if ip.enabled

        ip.update(enabled: true)
        enable_job(ip)
      end

      def disable(ip)
        return unless ip.enabled

        ip.update(enabled: false)
        disable_job(ip)
      end

      def delete(ip)
        disable(ip) if ip.enabled
        ip.delete
        Sidekiq::Cron::Job.destroy("ping_ip_#{ip.id}")
      end

      private

      def enable_job(ip)
        job = Sidekiq::Cron::Job.find("ping_ip_#{ip.id}")
        job&.enable!
      end

      def disable_job(ip)
        job = Sidekiq::Cron::Job.find("ping_ip_#{ip.id}")
        job&.disable!
      end
    end
  end
end
