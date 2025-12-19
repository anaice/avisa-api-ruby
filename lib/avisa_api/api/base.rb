# frozen_string_literal: true

module AvisaApi
  module Api
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      protected

      def get(path, params = {})
        client.get(path, params)
      end

      def post(path, body = {})
        client.post(path, body)
      end

      def delete(path)
        client.delete(path)
      end
    end
  end
end
