# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Contracts::Stats do
  subject(:contract) { described_class.new }

  describe 'validations' do
    it 'succeeds with valid params' do
      result = contract.call(
        time_from: (Time.now - 3600).iso8601,
        time_to: Time.now.iso8601
      )
      expect(result).to be_success
    end

    it 'fails without time_from' do
      result = contract.call(time_to: Time.now.iso8601)
      expect(result).to be_failure
      expect(result.errors[:time_from]).to include('is missing')
    end

    it 'fails without time_to' do
      result = contract.call(time_from: Time.now.iso8601)
      expect(result).to be_failure
      expect(result.errors[:time_to]).to include('is missing')
    end

    it 'fails with empty time_from' do
      result = contract.call(time_from: '', time_to: Time.now.iso8601)
      expect(result).to be_failure
      expect(result.errors[:time_from]).to include('must be filled')
    end

    it 'fails with empty time_to' do
      result = contract.call(time_from: Time.now.iso8601, time_to: '')
      expect(result).to be_failure
      expect(result.errors[:time_to]).to include('must be filled')
    end

    it 'fails with invalid time_from format' do
      result = contract.call(
        time_from: 'invalid-datetime',
        time_to: Time.now.iso8601
      )
      expect(result).to be_failure
      expect(result.errors[:time_from]).to include('must be a valid ISO8601 datetime string')
    end

    it 'fails with invalid time_to format' do
      result = contract.call(
        time_from: Time.now.iso8601,
        time_to: 'not-a-date'
      )
      expect(result).to be_failure
      expect(result.errors[:time_to]).to include('must be a valid ISO8601 datetime string')
    end

    it 'fails when time_to is before time_from' do
      time_from = Time.now.iso8601
      time_to = (Time.now - 3600).iso8601

      result = contract.call(time_from: time_from, time_to: time_to)
      expect(result).to be_failure
      expect(result.errors[:time_to]).to include('must be after time_from')
    end

    it 'fails when time_to equals time_from' do
      time = Time.now.iso8601
      result = contract.call(time_from: time, time_to: time)
      expect(result).to be_failure
      expect(result.errors[:time_to]).to include('must be after time_from')
    end

    it 'accepts UTC timestamps' do
      time_from = '2026-05-05T10:00:00Z'
      time_to = '2026-05-05T11:00:00Z'

      result = contract.call(time_from: time_from, time_to: time_to)
      expect(result).to be_success
    end

    it 'accepts timestamps with timezone' do
      time_from = '2026-05-05T10:00:00+03:00'
      time_to = '2026-05-05T11:00:00+03:00'

      result = contract.call(time_from: time_from, time_to: time_to)
      expect(result).to be_success
    end
  end
end
