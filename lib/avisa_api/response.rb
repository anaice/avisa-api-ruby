# frozen_string_literal: true

module AvisaApi
  class Response
    attr_reader :status, :body, :headers, :raw_response

    def initialize(faraday_response)
      @raw_response = faraday_response
      @status = faraday_response.status
      @body = parse_body(faraday_response.body)
      @headers = faraday_response.headers
    end

    def success?
      (200..299).cover?(@status)
    end

    def data
      @body
    end

    def error_message
      return nil if success?

      @body[:message] || @body[:error] || "HTTP #{@status}"
    end

    private

    def parse_body(body)
      return {} if body.nil? || body.empty?
      return body if body.is_a?(Hash)

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      { raw: body }
    end
  end
end
