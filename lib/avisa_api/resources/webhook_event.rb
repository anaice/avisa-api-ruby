# frozen_string_literal: true

module AvisaApi
  module Resources
    # Representa um evento recebido via webhook da AvisaAPI
    #
    # @example Uso no controller Rails
    #   def webhook
    #     event = AvisaApi::Resources::WebhookEvent.new(params)
    #
    #     if event.message?
    #       puts "Mensagem de #{event.sender_name}: #{event.text}"
    #       puts "Telefone: #{event.phone}"
    #     end
    #   end
    #
    class WebhookEvent
      attr_reader :raw_data

      # @param data [Hash] Payload recebido no webhook
      def initialize(data)
        @raw_data = data.is_a?(Hash) ? data : {}
        @event = @raw_data['event'] || @raw_data[:event] || {}
        @info = @event['Info'] || @event[:Info] || {}
        @message = @event['Message'] || @event[:Message] || {}
      end

      # ========================================
      # Tipo do Evento
      # ========================================

      # Tipo do evento recebido
      # @return [String] "Message", "Status", etc
      def type
        @raw_data['type'] || @raw_data[:type]
      end

      # @return [Boolean] true se é uma mensagem recebida
      def message?
        type == 'Message'
      end

      # @return [Boolean] true se é atualização de status
      def status?
        type == 'Status'
      end

      # ========================================
      # Informações do Remetente
      # ========================================

      # JID do chat (formato interno do WhatsApp)
      # @return [String] ex: "113365745688680@lid"
      def chat_jid
        @info['Chat'] || @info[:Chat]
      end

      # JID do remetente (formato interno)
      # @return [String] ex: "113365745688680@lid"
      def sender_jid
        @info['Sender'] || @info[:Sender]
      end

      # JID alternativo do remetente (formato padrão WhatsApp)
      # @return [String] ex: "5541999845097@s.whatsapp.net"
      def sender_alt_jid
        @info['SenderAlt'] || @info[:SenderAlt]
      end

      # Número de telefone do remetente (apenas dígitos com código do país)
      # @return [String] ex: "5541999845097"
      def phone
        jid = sender_alt_jid || sender_jid
        jid&.split('@')&.first
      end

      # Número formatado para enviar mensagem de resposta
      # @return [String] ex: "5541999845097"
      alias reply_to phone

      # Nome do contato no WhatsApp (push name)
      # @return [String] ex: "Rafael Anaice"
      def sender_name
        @info['PushName'] || @info[:PushName]
      end
      alias push_name sender_name

      # ========================================
      # Informações da Mensagem
      # ========================================

      # ID único da mensagem (usar para responder, reagir ou deletar)
      # @return [String] ex: "ACC395892777E41E58C6B555B3D1C338"
      def message_id
        @info['ID'] || @info[:ID]
      end
      alias id message_id

      # Tipo da mensagem
      # @return [String] "text", "image", "document", "audio", "video", "location", etc
      def message_type
        @info['Type'] || @info[:Type]
      end

      # Timestamp da mensagem
      # @return [Time, nil]
      def timestamp
        ts = @info['Timestamp'] || @info[:Timestamp]
        Time.parse(ts) if ts
      rescue ArgumentError
        nil
      end

      # @return [Boolean] true se a mensagem foi enviada por você (não recebida)
      def from_me?
        @info['IsFromMe'] == true || @info[:IsFromMe] == true
      end

      # @return [Boolean] true se é mensagem de grupo
      def group?
        @info['IsGroup'] == true || @info[:IsGroup] == true
      end

      # @return [Boolean] true se é mensagem efêmera
      def ephemeral?
        @event['IsEphemeral'] == true || @event[:IsEphemeral] == true
      end

      # @return [Boolean] true se é visualização única
      def view_once?
        @event['IsViewOnce'] == true || @event[:IsViewOnce] == true ||
          @event['IsViewOnceV2'] == true || @event[:IsViewOnceV2] == true
      end

      # @return [Boolean] true se é uma edição de mensagem
      def edit?
        @event['IsEdit'] == true || @event[:IsEdit] == true
      end

      # ========================================
      # Conteúdo da Mensagem
      # ========================================

      # Texto da mensagem (para mensagens de texto)
      # @return [String, nil]
      def text
        @message['conversation'] || @message[:conversation] ||
          @message['extendedTextMessage']&.dig('text') ||
          @message[:extendedTextMessage]&.dig(:text)
      end
      alias conversation text
      alias body text

      # Caption da mídia (para imagens, vídeos, documentos)
      # @return [String, nil]
      def caption
        @message['imageMessage']&.dig('caption') ||
          @message[:imageMessage]&.dig(:caption) ||
          @message['videoMessage']&.dig('caption') ||
          @message[:videoMessage]&.dig(:caption) ||
          @message['documentMessage']&.dig('caption') ||
          @message[:documentMessage]&.dig(:caption)
      end

      # Texto ou caption (o que estiver disponível)
      # @return [String, nil]
      def content
        text || caption
      end

      # ========================================
      # Verificadores de Tipo de Mídia
      # ========================================

      # @return [Boolean]
      def text?
        message_type == 'text'
      end

      # @return [Boolean]
      def image?
        message_type == 'image' || @message.key?('imageMessage') || @message.key?(:imageMessage)
      end

      # @return [Boolean]
      def video?
        message_type == 'video' || @message.key?('videoMessage') || @message.key?(:videoMessage)
      end

      # @return [Boolean]
      def audio?
        message_type == 'audio' || @message.key?('audioMessage') || @message.key?(:audioMessage)
      end

      # @return [Boolean]
      def document?
        message_type == 'document' || @message.key?('documentMessage') || @message.key?(:documentMessage)
      end

      # @return [Boolean]
      def location?
        message_type == 'location' || @message.key?('locationMessage') || @message.key?(:locationMessage)
      end

      # @return [Boolean]
      def sticker?
        message_type == 'sticker' || @message.key?('stickerMessage') || @message.key?(:stickerMessage)
      end

      # @return [Boolean]
      def contact?
        message_type == 'contact' || @message.key?('contactMessage') || @message.key?(:contactMessage)
      end

      # ========================================
      # Dados de Mídia
      # ========================================

      # Informações da imagem (se for mensagem de imagem)
      # @return [Hash, nil]
      def image_info
        @message['imageMessage'] || @message[:imageMessage]
      end

      # Informações do vídeo (se for mensagem de vídeo)
      # @return [Hash, nil]
      def video_info
        @message['videoMessage'] || @message[:videoMessage]
      end

      # Informações do áudio (se for mensagem de áudio)
      # @return [Hash, nil]
      def audio_info
        @message['audioMessage'] || @message[:audioMessage]
      end

      # Informações do documento (se for mensagem de documento)
      # @return [Hash, nil]
      def document_info
        @message['documentMessage'] || @message[:documentMessage]
      end

      # Informações de localização (se for mensagem de localização)
      # @return [Hash, nil]
      def location_info
        @message['locationMessage'] || @message[:locationMessage]
      end

      # ========================================
      # Contexto (para mensagens de resposta)
      # ========================================

      # Informações de contexto (quando é resposta a outra mensagem)
      # @return [Hash, nil]
      def context_info
        @message['contextInfo'] || @message[:contextInfo] ||
          @message['extendedTextMessage']&.dig('contextInfo') ||
          @message[:extendedTextMessage]&.dig(:contextInfo)
      end

      # ID da mensagem sendo respondida
      # @return [String, nil]
      def quoted_message_id
        context_info&.dig('stanzaId') || context_info&.dig(:stanzaId)
      end

      # @return [Boolean] true se é uma resposta a outra mensagem
      def reply?
        !quoted_message_id.nil?
      end

      # ========================================
      # Acesso Direto aos Dados
      # ========================================

      # Acesso direto ao hash Info
      # @return [Hash]
      def info
        @info
      end

      # Acesso direto ao hash Message
      # @return [Hash]
      def message
        @message
      end

      # Acesso direto ao hash event
      # @return [Hash]
      def event
        @event
      end

      # Representação em string para debug
      # @return [String]
      def to_s
        "#<WebhookEvent type=#{type} from=#{sender_name || phone} text=#{text&.truncate(50).inspect}>"
      end

      def inspect
        to_s
      end
    end
  end
end
