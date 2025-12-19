# frozen_string_literal: true

module AvisaApi
  class Configuration
    # URL base da API - configurável pelo usuário
    # @return [String]
    attr_accessor :base_url

    # Token de autenticação Bearer - obrigatório
    # @return [String]
    attr_accessor :token

    # Timeout em segundos para requisições
    # @return [Integer]
    attr_accessor :timeout

    # Logger opcional para debug
    # @return [Logger, nil]
    attr_accessor :logger

    # Opções de retry para requisições
    # @return [Hash]
    attr_accessor :retry_options

    DEFAULT_BASE_URL = 'https://www.avisaapi.com.br/api/'
    DEFAULT_TIMEOUT = 30

    def initialize(base_url: DEFAULT_BASE_URL, token: nil, timeout: DEFAULT_TIMEOUT, logger: nil, retry_options: nil)
      @base_url = normalize_base_url(base_url)
      @token = token
      @timeout = timeout
      @logger = logger
      @retry_options = retry_options || default_retry_options
    end

    def valid?
      !token.nil? && !token.empty?
    end

    private

    def normalize_base_url(url)
      url.end_with?('/') ? url : "#{url}/"
    end

    def default_retry_options
      {
        max: 2,
        interval: 0.5,
        backoff_factor: 2,
        exceptions: %w[Faraday::TimeoutError Faraday::ConnectionFailed]
      }
    end
  end
end
