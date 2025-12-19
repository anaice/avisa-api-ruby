# frozen_string_literal: true

module AvisaApi
  class Error < StandardError
    attr_reader :code, :details, :http_status

    def initialize(message = nil, code: nil, details: nil, http_status: nil)
      @code = code
      @details = details
      @http_status = http_status
      super(message)
    end
  end

  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
  class ServerError < Error; end
  class ConnectionError < Error; end
end
