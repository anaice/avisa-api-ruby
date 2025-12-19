# frozen_string_literal: true

require_relative 'base'

module AvisaApi
  module Api
    class Instance < Base
      # Obtém QR Code para conexão do WhatsApp
      #
      # @return [Response] Contém QR Code em base64 ou status se já conectado
      #
      # @example
      #   response = client.instance.qr_code
      #   if response.success?
      #     puts response.data[:qr] # Base64 do QR Code
      #   end
      #
      def qr_code
        get('/instance/qr')
      end

      # Obtém status da instância
      #
      # @return [Response] Contém informações de status
      #   - LoggedIn: true/false
      #   - phone: número conectado
      #   - name: nome do perfil
      #
      # @example
      #   response = client.instance.status
      #   puts response.data[:LoggedIn] # => true
      #
      def status
        get('/instance/status')
      end

      # Verifica se a instância está conectada
      #
      # @return [Boolean]
      def connected?
        response = status
        response.success? && response.data[:LoggedIn] == true
      end

      # Deleta/desconecta a instância
      #
      # @return [Response]
      def delete
        delete('/instance/user')
      end

      # Cria um novo usuário (apenas para integradores)
      # Requer token de integrador especial
      #
      # @param name [String] Nome do usuário
      # @param email [String] Email do usuário
      # @return [Response] Contém token do novo usuário
      def create_user(name:, email:)
        post('/instance/createUser', { name: name, email: email })
      end

      # Lista todos os usuários (apenas para integradores)
      # Requer token de integrador especial
      #
      # @return [Response] Lista de usuários
      def list_users
        get('/instance/getAll')
      end
    end
  end
end
