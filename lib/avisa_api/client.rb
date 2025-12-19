# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'
require 'json'

# Ensure JSON middleware is loaded
require 'faraday/request/json'
require 'faraday/response/json'

require_relative 'api/base'
require_relative 'api/messages'
require_relative 'api/instance'
require_relative 'api/webhook'
require_relative 'api/validation'
require_relative 'api/groups'
require_relative 'api/chat'

module AvisaApi
  class Client
    attr_reader :config

    # Inicializa o cliente AvisaApi
    #
    # @param base_url [String] URL base da API (opcional, usa config global ou default)
    # @param token [String] Token de autenticação Bearer (obrigatório)
    # @param timeout [Integer] Timeout em segundos (opcional, default: 30)
    # @param logger [Logger] Logger para debug (opcional)
    #
    # @example Uso direto
    #   client = AvisaApi::Client.new(token: 'seu_token')
    #
    # @example Com configuração customizada
    #   client = AvisaApi::Client.new(
    #     base_url: 'https://custom.api.com',
    #     token: 'seu_token',
    #     timeout: 60
    #   )
    #
    # @example Usando configuração global
    #   AvisaApi.configure do |c|
    #     c.token = 'seu_token'
    #   end
    #   client = AvisaApi::Client.new
    #
    def initialize(base_url: nil, token: nil, timeout: nil, logger: nil)
      @config = build_config(base_url: base_url, token: token, timeout: timeout, logger: logger)
      validate_config!
      @connection = build_connection
    end

    # Módulo de mensagens
    # @return [Api::Messages]
    def messages
      @messages ||= Api::Messages.new(self)
    end

    # Módulo de instância WhatsApp
    # @return [Api::Instance]
    def instance
      @instance ||= Api::Instance.new(self)
    end

    # Módulo de webhook
    # @return [Api::Webhook]
    def webhook
      @webhook ||= Api::Webhook.new(self)
    end

    # Módulo de validação de números
    # @return [Api::Validation]
    def validation
      @validation ||= Api::Validation.new(self)
    end

    # Módulo de grupos
    # @return [Api::Groups]
    def groups
      @groups ||= Api::Groups.new(self)
    end

    # Módulo de chat
    # @return [Api::Chat]
    def chat
      @chat ||= Api::Chat.new(self)
    end

    # Executa requisição GET
    # @param path [String] Caminho da API
    # @param params [Hash] Parâmetros de query string
    # @return [Response]
    def get(path, params = {})
      request(:get, path, params: params)
    end

    # Executa requisição POST
    # @param path [String] Caminho da API
    # @param body [Hash] Corpo da requisição
    # @return [Response]
    def post(path, body = {})
      request(:post, path, body: body)
    end

    # Executa requisição DELETE
    # @param path [String] Caminho da API
    # @return [Response]
    def delete(path)
      request(:delete, path)
    end

    private

    def build_config(base_url:, token:, timeout:, logger:)
      global_config = AvisaApi.configuration || Configuration.new

      Configuration.new(
        base_url: base_url || global_config.base_url,
        token: token || global_config.token,
        timeout: timeout || global_config.timeout,
        logger: logger || global_config.logger,
        retry_options: global_config.retry_options
      )
    end

    def validate_config!
      raise ArgumentError, 'Token is required' unless @config.valid?
    end

    def build_connection
      Faraday.new(url: @config.base_url) do |conn|
        conn.request :json
        conn.response :json, parser_options: { symbolize_names: true }
        conn.response :logger, @config.logger, bodies: true if @config.logger

        conn.request :retry, @config.retry_options if @config.retry_options[:max].positive?

        conn.headers['Authorization'] = "Bearer #{@config.token}"
        conn.headers['Content-Type'] = 'application/json'
        conn.headers['Accept'] = 'application/json'

        conn.options.timeout = @config.timeout
        conn.options.open_timeout = @config.timeout

        conn.adapter Faraday.default_adapter
      end
    end

    def request(method, path, params: {}, body: nil)
      # Remove barra inicial para concatenar corretamente com base_url
      normalized_path = path.sub(%r{^/}, '')

      response = case method
                 when :get
                   @connection.get(normalized_path, params)
                 when :post
                   @connection.post(normalized_path, body)
                 when :delete
                   @connection.delete(normalized_path)
                 end

      # Check for HTTP error status codes and raise appropriate errors
      handle_http_error(response) if response.status >= 400

      Response.new(response)
    rescue Faraday::ConnectionFailed => e
      raise ConnectionError.new("Connection failed: #{e.message}", http_status: nil)
    rescue Faraday::TimeoutError => e
      raise ConnectionError.new("Request timeout: #{e.message}", http_status: nil)
    end

    def handle_http_error(response)
      status = response.status
      body = response.body

      case status
      when 401
        raise AuthenticationError.new('Invalid token', http_status: status, details: body)
      when 404
        raise NotFoundError.new('Resource not found', http_status: status, details: body)
      when 429
        raise RateLimitError.new('Rate limit exceeded (240 req/min)', http_status: status, details: body)
      when 400..499
        message = body.is_a?(Hash) ? (body[:message] || body['message'] || 'Client error') : 'Client error'
        raise ValidationError.new(message, http_status: status, details: body)
      when 500..599
        raise ServerError.new('Server error', http_status: status, details: body)
      else
        raise Error.new("HTTP Error: #{status}", http_status: status, details: body)
      end
    end
  end
end
