# frozen_string_literal: true

require_relative 'base'

module AvisaApi
  module Api
    class Validation < Base
      # Verifica se número possui WhatsApp
      #
      # @param number [String] Número no formato brasileiro (ex: '(51) 9999-99999' ou '51999999999')
      # @return [Response] Contém:
      #   - exists: true/false
      #   - jid: JID do WhatsApp se existir
      #
      # @example
      #   response = client.validation.check_number(number: '51999999999')
      #   if response.data[:exists]
      #     puts "WhatsApp encontrado: #{response.data[:jid]}"
      #   end
      #
      def check_number(number:)
        post('/actions/checknumber', { number: number })
      end

      # Verifica se número internacional possui WhatsApp
      #
      # @param number [String] Número com código do país (ex: '+5551999999999')
      # @return [Response]
      def check_number_international(number:)
        post('/actions/checknumberinternational', { number: number })
      end

      # Verifica se número possui WhatsApp (alias)
      alias exists? check_number

      # Verifica múltiplos números
      #
      # @param numbers [Array<String>] Lista de números
      # @return [Array<Response>]
      def check_numbers(numbers)
        numbers.map { |number| check_number(number: number) }
      end
    end
  end
end
