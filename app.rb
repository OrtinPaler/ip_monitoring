# frozen_string_literal: true

require 'json'
require 'roda'

require_relative 'config/database'
require_relative 'config/environment'

require_relative 'app/models/ip'
require_relative 'app/services/ip'
require_relative 'app/services/stats'

class App < Roda
  plugin :json
  plugin :json_parser,
         error_handler: ->(e) {
           response.status = 422
           { error: 'Request body contains invalid JSON', details: e.message }
         }

  plugin :all_verbs
  plugin :halt
  plugin :request_headers

  plugin :error_handler do |e|
    case e
    when AppError
      response.status = e.status_code
      { error: e.message }
    when Sequel::ValidationFailed
      response.status = 422
      { error: e.message }
    else
      response.status = 500
      { error: 'Internal server error' }
    end
  end

  route do |r|
    r.on 'ips' do
      r.is do
        r.post do
          result = Services::Ip.create(JSON.parse(r.body.read))
          response.status = 201
          result
        end
      end

      r.on Integer do |id|
        ip = Ip.find(id:) || raise(AppError.new('IP not found', 404))

        r.patch 'enable' do
          Services::Ip.enable(ip)
          { message: 'IP enabled' }
        end

        r.patch 'disable' do
          Services::Ip.disable(ip)
          { message: 'IP disabled' }
        end

        r.get 'stats' do
          validation = Services::Stats.validate(r.params)
          if validation[:errors]
            raise AppError.new("Invalid params: #{validation[:errors].to_json}")
          end

          stats = Services::Stats.calculate(ip, validation[:time_from], validation[:time_to])
          raise AppError.new(stats[:error], 404) if stats[:error]
          stats
        end

        r.delete do
          Services::Ip.delete(ip)
          { message: 'IP deleted' }
        end
      end
    end
  end
end
