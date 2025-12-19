# frozen_string_literal: true

module AvisaApi
  module Tui
    class InstanceMenu
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
          app.send(:show_header, 'Instance Management')

          choice = prompt.select('Select option:', cycle: true) do |menu|
            menu.choice 'Check Status', :status
            menu.choice 'Get QR Code', :qr_code
            menu.choice 'Disconnect Instance', :disconnect
            menu.choice 'Reconnect Instance', :reconnect
            menu.choice pastel.dim('Back'), :back
          end

          break if choice == :back

          case choice
          when :status then check_status
          when :qr_code then get_qr_code
          when :disconnect then disconnect
          when :reconnect then reconnect
          end
        end
      end

      private

      def check_status
        app.send(:clear_screen)
        app.send(:show_header, 'Instance Status')

        spinner = TTY::Spinner.new("[:spinner] Checking status...", format: :dots)
        spinner.auto_spin

        begin
          response = client.instance.status
          spinner.stop

          if response.success?
            puts pastel.green("\nInstance Status:")
            puts

            data = response.data
            if data.is_a?(Hash)
              table = TTY::Table.new do |t|
                data.each do |key, value|
                  t << [pastel.bold(key.to_s), value.to_s]
                end
              end
              puts table.render(:unicode, padding: [0, 1])
            else
              puts data
            end
          else
            puts pastel.red("\nFailed to get status")
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def get_qr_code
        app.send(:clear_screen)
        app.send(:show_header, 'QR Code')

        spinner = TTY::Spinner.new("[:spinner] Getting QR code...", format: :dots)
        spinner.auto_spin

        begin
          response = client.instance.qr_code
          spinner.stop

          if response.success?
            data = response.data

            if data[:qrcode] || data[:qr] || data[:code]
              qr_data = data[:qrcode] || data[:qr] || data[:code]

              puts pastel.green("\nQR Code received!")
              puts
              puts "If you have a QR code terminal renderer, you can use the data below:"
              puts pastel.dim("-" * 50)
              puts qr_data
              puts pastel.dim("-" * 50)

              # Try to display as ASCII if it looks like a URL or short string
              if qr_data.length < 500
                puts
                puts pastel.yellow("Scan this QR code with your WhatsApp app")
              end

              # Save option
              if prompt.yes?("\nWould you like to save the QR data to a file?")
                filename = prompt.ask('Filename:', default: 'qrcode.txt')
                File.write(filename, qr_data)
                puts pastel.green("Saved to #{filename}")
              end
            elsif data[:status] == 'connected' || data[:connected]
              puts pastel.green("\nInstance is already connected!")
              puts "No QR code needed."
            else
              puts pastel.yellow("\nQR Code data:")
              puts data.inspect
            end
          else
            puts pastel.red("\nFailed to get QR code")
            puts "Status: #{response.status}"
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def disconnect
        app.send(:clear_screen)
        app.send(:show_header, 'Disconnect Instance')

        confirm = prompt.yes?("Are you sure you want to disconnect?")
        return unless confirm

        spinner = TTY::Spinner.new("[:spinner] Disconnecting...", format: :dots)
        spinner.auto_spin

        begin
          response = client.instance.disconnect
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def reconnect
        app.send(:clear_screen)
        app.send(:show_header, 'Reconnect Instance')

        spinner = TTY::Spinner.new("[:spinner] Reconnecting...", format: :dots)
        spinner.auto_spin

        begin
          response = client.instance.reconnect
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
