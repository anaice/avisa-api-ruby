# frozen_string_literal: true

module AvisaApi
  module Tui
    class App
      attr_reader :prompt, :pastel, :client

      def initialize
        @prompt = TTY::Prompt.new
        @pastel = Pastel.new
        @client = nil
      end

      def run
        clear_screen
        show_banner
        setup_client
        main_menu
      rescue Interrupt
        puts "\n\n#{pastel.yellow('Bye!')}"
        exit(0)
      end

      private

      def clear_screen
        print "\e[2J\e[H"
      end

      def show_banner
        box = TTY::Box.frame(
          width: 50,
          height: 7,
          align: :center,
          padding: 1,
          title: { top_left: pastel.green(' AvisaAPI ') }
        ) do
          [
            pastel.bold.green('WhatsApp TUI Client'),
            '',
            pastel.dim('Powered by AvisaAPI (avisaapi.com.br)')
          ].join("\n")
        end
        puts box
        puts
      end

      def setup_client
        token = prompt.mask('Enter your API Token:') do |q|
          q.required true
          q.validate(/\A.{10,}\z/, 'Token must be at least 10 characters')
        end

        base_url = prompt.ask('Base URL (press Enter for default):', default: AvisaApi::Configuration::DEFAULT_BASE_URL)

        spinner = TTY::Spinner.new("[:spinner] Connecting to API...", format: :dots)
        spinner.auto_spin

        begin
          @client = AvisaApi::Client.new(token: token, base_url: base_url)
          response = @client.instance.status

          spinner.stop

          if response.success?
            puts pastel.green("\nConnected successfully!")
            show_instance_info(response.data)
          else
            puts pastel.red("\nWarning: Could not verify connection")
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nConnection error: #{e.message}")
          retry_setup = prompt.yes?('Try again?')
          retry_setup ? setup_client : exit(1)
        end

        puts
      end

      def show_instance_info(data)
        return unless data.is_a?(Hash)

        info = []
        info << "Instance: #{data[:instance] || data[:name] || 'N/A'}"
        info << "Status: #{data[:status] || 'N/A'}"
        info << "Phone: #{data[:phone] || data[:number] || 'N/A'}"

        puts pastel.dim(info.join(' | '))
      end

      def main_menu
        loop do
          clear_screen
          show_header('Main Menu')

          choice = prompt.select('What would you like to do?', cycle: true, per_page: 10) do |menu|
            menu.choice 'Messages', :messages
            menu.choice 'Instance Management', :instance
            menu.choice 'Groups', :groups
            menu.choice 'Webhooks', :webhooks
            menu.choice 'Chat', :chat
            menu.choice 'Validate Number', :validate
            menu.choice pastel.red('Exit'), :exit
          end

          case choice
          when :messages
            MessagesMenu.new(self).show
          when :instance
            InstanceMenu.new(self).show
          when :groups
            GroupsMenu.new(self).show
          when :webhooks
            WebhookMenu.new(self).show
          when :chat
            ChatMenu.new(self).show
          when :validate
            validate_number
          when :exit
            puts pastel.yellow("\nBye!")
            break
          end
        end
      end

      def validate_number
        clear_screen
        show_header('Validate Number')

        number = prompt.ask('Enter phone number to validate:') do |q|
          q.required true
          q.validate(/\A\d{10,15}\z/, 'Enter a valid phone number (10-15 digits)')
        end

        spinner = TTY::Spinner.new("[:spinner] Validating...", format: :dots)
        spinner.auto_spin

        begin
          response = @client.validation.check_number(number: number)
          spinner.stop

          if response.success?
            data = response.data
            if data[:exists] || data[:valid]
              puts pastel.green("\nNumber is valid and registered on WhatsApp!")
              puts "JID: #{data[:jid] || data[:number]}" if data[:jid] || data[:number]
            else
              puts pastel.yellow("\nNumber is NOT registered on WhatsApp")
            end
          else
            puts pastel.red("\nCould not validate: #{response.body}")
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def show_header(title)
        puts pastel.bold.cyan("=== #{title} ===")
        puts
      end

      def show_response(response)
        if response.success?
          puts pastel.green("\nSuccess!")
          if response.data.is_a?(Hash)
            response.data.each do |key, value|
              puts "  #{pastel.bold(key)}: #{value}"
            end
          else
            puts "  #{response.data}"
          end
        else
          puts pastel.red("\nFailed!")
          puts "  Status: #{response.status}"
          puts "  Body: #{response.body}"
        end
      end
    end
  end
end
