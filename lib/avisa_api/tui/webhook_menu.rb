# frozen_string_literal: true

module AvisaApi
  module Tui
    class WebhookMenu
      attr_reader :app, :prompt, :pastel, :client

      def initialize(app)
        @app = app
        @prompt = app.prompt
        @pastel = app.pastel
        @client = app.client
      end

      def show
        loop do
          app.send(:clear_screen)
          app.send(:show_header, 'Webhooks')

          choice = prompt.select('Select option:', cycle: true) do |menu|
            menu.choice 'Show Current Webhook', :show
            menu.choice 'Set Webhook URL', :set
            menu.choice 'Remove Webhook', :remove
            menu.choice pastel.dim('Back'), :back
          end

          break if choice == :back

          case choice
          when :show then show_webhook
          when :set then set_webhook
          when :remove then remove_webhook
          end
        end
      end

      private

      def show_webhook
        app.send(:clear_screen)
        app.send(:show_header, 'Current Webhook')

        spinner = TTY::Spinner.new("[:spinner] Loading webhook...", format: :dots)
        spinner.auto_spin

        begin
          response = client.webhook.show
          spinner.stop

          if response.success?
            data = response.data
            puts pastel.green("\nWebhook Configuration:")
            puts

            if data.is_a?(Hash) && !data.empty?
              table = TTY::Table.new do |t|
                data.each do |key, value|
                  t << [pastel.bold(key.to_s), value.to_s.empty? ? '(empty)' : value.to_s]
                end
              end
              puts table.render(:unicode, padding: [0, 1])
            elsif data.is_a?(String) && !data.empty?
              puts "Webhook URL: #{data}"
            else
              puts pastel.yellow("No webhook configured")
            end
          else
            puts pastel.red("\nFailed to get webhook")
            puts "Status: #{response.status}"
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def set_webhook
        app.send(:clear_screen)
        app.send(:show_header, 'Set Webhook')

        url = prompt.ask('Webhook URL:') do |q|
          q.required true
          q.validate(%r{\Ahttps?://}, 'Please enter a valid URL starting with http:// or https://')
        end

        spinner = TTY::Spinner.new("[:spinner] Setting webhook...", format: :dots)
        spinner.auto_spin

        begin
          response = client.webhook.set(url: url)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def remove_webhook
        app.send(:clear_screen)
        app.send(:show_header, 'Remove Webhook')

        confirm = prompt.yes?(pastel.yellow("Are you sure you want to remove the webhook?"))
        return unless confirm

        spinner = TTY::Spinner.new("[:spinner] Removing webhook...", format: :dots)
        spinner.auto_spin

        begin
          response = client.webhook.remove
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end
    end
  end
end
