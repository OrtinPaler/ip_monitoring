# frozen_string_literal: true

require_relative '../contracts/stats'

module Services
  class Stats
    class << self
      def validate(params)
        contract = Contracts::Stats.new
        result = contract.call(params)

        if result.failure?
          { errors: result.errors.to_h }
        else
          {
            time_from: Time.parse(params['time_from']),
            time_to: Time.parse(params['time_to'])
          }
        end
      end

      def calculate(ip, time_from, time_to)
        result = DB[stats_sql, ip.id, time_from, time_to].first
        return { error: "No ping data available for this period" } if result[:total_pings] == 0

        result
      end

      private

      def stats_sql
        <<~SQL
          WITH period_pings AS (
            SELECT rtt, success
            FROM pings
            WHERE ip_id = ? AND created_at BETWEEN ? AND ?
          )

          SELECT COUNT(*) as total_pings,
                 COUNT(*) FILTER (WHERE success) as successful_pings,
                 COUNT(*) FILTER (WHERE NOT success) as failed_pings,
                 COALESCE(ROUND(AVG(rtt)::numeric, 4), 0) as avg_rtt,
                 COALESCE(ROUND(MIN(rtt)::numeric, 4), 0) as min_rtt,
                 COALESCE(ROUND(MAX(rtt)::numeric, 4), 0) as max_rtt,
                 COALESCE(ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rtt)::numeric, 4), 0) as median_rtt,
                 COALESCE(ROUND(STDDEV(rtt) FILTER (WHERE success)::numeric, 4), 0) as stddev_rtt,
                 COALESCE(ROUND((COUNT(*) FILTER (WHERE NOT success)::float / NULLIF(COUNT(*), 0)::float * 100)::numeric, 2), 0) as packet_loss_percent
          FROM period_pings
        SQL
      end
    end
  end
end
