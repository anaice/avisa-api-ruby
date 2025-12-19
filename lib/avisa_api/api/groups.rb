# frozen_string_literal: true

require_relative 'base'

module AvisaApi
  module Api
    class Groups < Base
      # Lista todos os grupos
      #
      # @return [Response] Lista de grupos
      def list
        get('/group/list')
      end

      # Obtém informações de um grupo
      #
      # @param group_id [String] ID do grupo (ex: '123456789@g.us')
      # @return [Response]
      def info(group_id:)
        get('/group/info', { id: group_id })
      end

      # Envia mensagem de texto para grupo
      #
      # @param group_id [String] ID do grupo
      # @param message [String] Mensagem
      # @return [Response]
      def send_text(group_id:, message:)
        post('/actions/sendMessageGroup', { id: group_id, message: message })
      end

      # Cria um novo grupo
      #
      # @param name [String] Nome do grupo
      # @param participants [Array<String>] Lista de números dos participantes
      # @return [Response]
      def create(name:, participants:)
        post('/group/create', { name: name, participants: participants })
      end

      # Atualiza participantes do grupo
      #
      # @param group_id [String] ID do grupo
      # @param participants_add [Array<String>] Participantes a adicionar
      # @param participants_remove [Array<String>] Participantes a remover
      # @return [Response]
      def update(group_id:, participants_add: [], participants_remove: [])
        body = { id: group_id }
        body[:add] = participants_add unless participants_add.empty?
        body[:remove] = participants_remove unless participants_remove.empty?

        post('/group/update', body)
      end

      # Altera nome do grupo
      #
      # @param group_id [String] ID do grupo
      # @param name [String] Novo nome
      # @return [Response]
      def change_name(group_id:, name:)
        post('/group/name', { id: group_id, name: name })
      end

      # Altera descrição do grupo
      #
      # @param group_id [String] ID do grupo
      # @param description [String] Nova descrição
      # @return [Response]
      def change_description(group_id:, description:)
        post('/group/description', { id: group_id, description: description })
      end

      # Altera foto do grupo
      #
      # @param group_id [String] ID do grupo
      # @param base64 [String] Imagem em Base64
      # @return [Response]
      def change_photo(group_id:, base64:)
        post('/group/photo', { id: group_id, image: base64 })
      end

      # Configura se apenas admins podem enviar mensagens
      #
      # @param group_id [String] ID do grupo
      # @param enabled [Boolean] true = apenas admins, false = todos
      # @return [Response]
      def set_admin_only(group_id:, enabled:)
        post('/group/adminonly', { id: group_id, adminonly: enabled })
      end
    end
  end
end
