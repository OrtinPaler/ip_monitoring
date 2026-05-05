# frozen_string_literal: true

require 'dry-validation'

module Contracts
  class Stats < Dry::Validation::Contract
    params do
      required(:time_from).filled(:string)
      required(:time_to).filled(:string)
    end

    rule(:time_from) do
      Time.parse(value)
    rescue ArgumentError
      key.failure('must be a valid ISO8601 datetime string')
    end

    rule(:time_to) do
      Time.parse(value)
    rescue ArgumentError
      key.failure('must be a valid ISO8601 datetime string')
    end

    rule(:time_to, :time_from) do
      unless rule_error?(:time_from) || rule_error?(:time_to)
        time_from = Time.parse(values[:time_from])
        time_to = Time.parse(values[:time_to])
        key.failure('must be after time_from') if time_to <= time_from
      end
    end
  end
end
