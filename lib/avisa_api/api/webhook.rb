# frozen_string_literal: true

require_relative 'base'

module AvisaApi
  module Api
    class Webhook < Base
      # Obtém webhook configurado atualmente
      #
      # @return [Response] Contém URL do webhook ou vazio se não configurado
      #
      # @example
      #   response = client.webhook.show
      #   puts response.data[:webhook] # => 'https://meusite.com/webhook'
      #
      def show
        get('/webhook')
      end

      # Configura URL do webhook
      #
      # @param url [String] URL que receberá os eventos
      # @return [Response]
      #
      # @example
      #   client.webhook.set(url: 'https://meusite.com/api/whatsapp/webhook')
      #
      def set(url:)
        post('/webhook', { webhook: url })
      end

      # Remove webhook configurado
      #
      # @return [Response]
      def remove
        post('/webhook', { webhook: '' })
      end

      # Alias para show
      alias get_config show

      # Alias para set
      alias update set
    end
  end
end
