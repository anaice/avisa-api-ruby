# frozen_string_literal: true

require_relative 'base'

module AvisaApi
  module Api
    class Chat < Base
      # Arquiva ou desarquiva um chat
      #
      # @param number [String] Número do chat
      # @param archive [Boolean] true para arquivar, false para desarquivar
      # @return [Response]
      def archive(number:, archive: true)
        post('/chat/archive', { number: number, archive: archive })
      end

      # Inicia indicador de "digitando..."
      #
      # @param number [String] Número do chat
      # @return [Response]
      def start_typing(number:)
        post('/chat/typing/start', { number: number })
      end

      # Para indicador de "digitando..."
      #
      # @param number [String] Número do chat
      # @return [Response]
      def stop_typing(number:)
        post('/chat/typing/stop', { number: number })
      end

      # Inicia indicador de "gravando áudio..."
      #
      # @param number [String] Número do chat
      # @return [Response]
      def start_recording(number:)
        post('/chat/recording/start', { number: number })
      end

      # Para indicador de "gravando áudio..."
      #
      # @param number [String] Número do chat
      # @return [Response]
      def stop_recording(number:)
        post('/chat/recording/stop', { number: number })
      end

      # Simula digitação antes de enviar mensagem
      # Útil para parecer mais humano
      #
      # @param number [String] Número do chat
      # @param duration [Integer] Duração em segundos (default: 2)
      # @yield Bloco a executar após digitação
      def with_typing(number:, duration: 2)
        start_typing(number: number)
        sleep(duration)
        result = yield if block_given?
        stop_typing(number: number)
        result
      end
    end
  end
end
