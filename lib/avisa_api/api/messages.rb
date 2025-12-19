# frozen_string_literal: true

require_relative 'base'

module AvisaApi
  module Api
    class Messages < Base
      # Envia mensagem de texto
      #
      # @param number [String] Número do destinatário (ex: '5511999999999')
      # @param message [String] Conteúdo da mensagem
      # @param id [String, nil] ID customizado da mensagem (opcional)
      # @param context_info [Hash, nil] Contexto para responder mensagem (opcional)
      #   - stanza_id: ID da mensagem original
      #   - participant: Remetente da mensagem original
      # @return [Response]
      #
      # @example Envio simples
      #   client.messages.send_text(number: '5511999999999', message: 'Olá!')
      #
      # @example Responder mensagem
      #   client.messages.send_text(
      #     number: '5511999999999',
      #     message: 'Respondendo...',
      #     context_info: { stanza_id: 'MSG_ID', participant: '5511888888888@s.whatsapp.net' }
      #   )
      #
      def send_text(number:, message:, id: nil, context_info: nil)
        body = { number: number, message: message }
        body[:id] = id if id
        body[:contextInfo] = format_context_info(context_info) if context_info

        post('/actions/sendMessage', body)
      end

      # Envia mensagem de texto para número internacional
      #
      # @param number [String] Número com código do país (ex: '+5511999999999')
      # @param message [String] Conteúdo da mensagem
      # @return [Response]
      def send_text_international(number:, message:)
        post('/actions/sendMessageInternational', { number: number, message: message })
      end

      # Edita uma mensagem enviada
      #
      # @param number [String] Número do chat
      # @param id [String] ID da mensagem a editar
      # @param message [String] Novo conteúdo
      # @return [Response]
      def edit(number:, id:, message:)
        post('/actions/editMessage', { number: number, id: id, message: message })
      end

      # Deleta uma mensagem
      #
      # @param number [String] Número do chat
      # @param id [String] ID da mensagem a deletar
      # @return [Response]
      def delete_message(number:, id:)
        post('/actions/deleteMessage', { number: number, id: id })
      end

      # Marca mensagens como lidas
      #
      # @param sender [String] JID do remetente (ex: '5511999999999@s.whatsapp.net')
      # @param chat [String] JID do chat
      # @param ids [Array<String>] IDs das mensagens
      # @return [Response]
      def mark_read(sender:, chat:, ids:)
        post('/actions/markreadMessage', { sender: sender, chat: chat, id: ids })
      end

      # Reage a uma mensagem com emoji
      #
      # @param number [String] JID do chat (ex: '5511999999999@s.whatsapp.net')
      # @param id [String] ID da mensagem
      # @param emoji [String] Emoji da reação
      # @return [Response]
      def react(number:, id:, emoji:)
        post('/actions/reactMessage', { number: number, id: id, react: emoji })
      end

      # Envia mídia via URL
      #
      # @param number [String] Número do destinatário
      # @param file_url [String] URL da mídia
      # @param caption [String, nil] Legenda (opcional)
      # @param media_type [String] Tipo: 'image', 'video', 'audio', 'document'
      # @param file_name [String, nil] Nome do arquivo (obrigatório para document)
      # @return [Response]
      def send_media(number:, url:, caption: nil, media_type: 'image', file_name: nil)
        body = { number: number, fileUrl: url, type: media_type }
        body[:message] = caption if caption
        body[:fileName] = file_name if file_name

        post('/actions/sendMedia', body)
      end

      # Envia imagem em Base64
      #
      # @param number [String] Número do destinatário
      # @param base64 [String] Imagem em Base64 (com prefixo data:image/...)
      # @param message [String, nil] Legenda (opcional)
      # @return [Response]
      def send_image(number:, base64:, message: nil)
        body = { number: number, image: base64 }
        body[:message] = message if message

        post('/actions/sendImage', body)
      end

      # Envia documento em Base64
      #
      # @param number [String] Número do destinatário
      # @param base64 [String] Documento em Base64
      # @param filename [String] Nome do arquivo
      # @param caption [String, nil] Legenda (opcional)
      # @return [Response]
      def send_document(number:, base64:, filename:, caption: nil)
        body = { number: number, document: base64, fileName: filename }
        body[:caption] = caption if caption

        post('/actions/sendDocument', body)
      end

      # Envia áudio em Base64 (formato OGG)
      #
      # @param number [String] Número do destinatário
      # @param base64 [String] Áudio em Base64 (OGG)
      # @return [Response]
      def send_audio(number:, base64:)
        post('/actions/sendAudio', { number: number, audio: base64 })
      end

      # Envia localização
      #
      # @param number [String] Número do destinatário
      # @param latitude [Float] Latitude
      # @param longitude [Float] Longitude
      # @param name [String, nil] Nome do local (opcional)
      # @return [Response]
      def send_location(number:, latitude:, longitude:, name: nil)
        body = {
          number: number,
          latitude: latitude.to_f,
          longitude: longitude.to_f
        }
        body[:name] = name if name && !name.empty?

        post('/actions/sendLocation', body)
      end

      # Envia preview de link
      #
      # @param number [String] Número do destinatário
      # @param message [String] Mensagem com o link
      # @param url [String] URL para preview
      # @param image [String] Imagem de preview em Base64
      # @param title [String, nil] Título customizado (opcional)
      # @param description [String, nil] Descrição customizada (opcional)
      # @return [Response]
      def send_preview(number:, message:, url:, image:, title: nil, description: nil)
        body = { number: number, message: message, urlSite: url, image: image }
        body[:title] = title if title && !title.empty?
        body[:description] = description if description && !description.empty?

        post('/actions/sendPreview', body)
      end

      # Envia mensagem de texto assíncrona
      #
      # @param number [String] Número do destinatário
      # @param message [String] Conteúdo da mensagem
      # @return [Response] Contém ID para consulta posterior
      def send_text_async(number:, message:)
        post('/actions/sendMessageAsync', { number: number, message: message })
      end

      # Consulta resultado de mensagem assíncrona
      #
      # @param id [String] ID retornado pelo send_text_async
      # @return [Response]
      def get_async_result(id:)
        get('/actions/getSendMessageAsync', { id: id })
      end

      # Download de imagem recebida
      #
      # @param media_info [Hash] Informações da mídia recebida via webhook
      # @return [Response]
      def download_image(media_info)
        post('/message/download/image', media_info)
      end

      # Download de vídeo recebido
      #
      # @param media_info [Hash] Informações da mídia recebida via webhook
      # @return [Response]
      def download_video(media_info)
        post('/message/download/video', media_info)
      end

      # Download de documento recebido
      #
      # @param media_info [Hash] Informações da mídia recebida via webhook
      # @return [Response]
      def download_document(media_info)
        post('/message/download/document', media_info)
      end

      private

      def format_context_info(context_info)
        {
          StanzaId: context_info[:stanza_id],
          Participant: context_info[:participant]
        }
      end
    end
  end
end
