# frozen_string_literal: true

class AppError < StandardError
  attr_reader :status_code

  def initialize(message, status_code = 422)
    super(message)
    @status_code = status_code
  end
end
