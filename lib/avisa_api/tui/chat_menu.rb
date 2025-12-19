# frozen_string_literal: true

module AvisaApi
  module Tui
    class ChatMenu
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
          app.send(:show_header, 'Chat')

          choice = prompt.select('Select option:', cycle: true) do |menu|
            menu.choice 'List Chats', :list
            menu.choice 'Get Messages from Chat', :messages
            menu.choice 'Mark as Read', :read
            menu.choice 'Archive Chat', :archive
            menu.choice 'Unarchive Chat', :unarchive
            menu.choice 'Pin Chat', :pin
            menu.choice 'Unpin Chat', :unpin
            menu.choice 'Delete Chat', :delete
            menu.choice pastel.dim('Back'), :back
          end

          break if choice == :back

          case choice
          when :list then list_chats
          when :messages then get_messages
          when :read then mark_as_read
          when :archive then archive_chat
          when :unarchive then unarchive_chat
          when :pin then pin_chat
          when :unpin then unpin_chat
          when :delete then delete_chat
          end
        end
      end

      private

      def list_chats
        app.send(:clear_screen)
        app.send(:show_header, 'List Chats')

        spinner = TTY::Spinner.new("[:spinner] Loading chats...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.list
          spinner.stop

          if response.success?
            chats = response.data[:chats] || response.data

            if chats.is_a?(Array) && chats.any?
              puts pastel.green("\nFound #{chats.size} chat(s):\n")

              table = TTY::Table.new(header: ['Name', 'Number/ID', 'Unread', 'Last Message'])
              chats.first(20).each do |chat|
                table << [
                  (chat[:name] || chat[:pushName] || 'N/A')[0..20],
                  chat[:id] || chat[:jid] || 'N/A',
                  chat[:unreadCount] || chat[:unread] || 0,
                  (chat[:lastMessage] || chat[:last_message] || '')[0..30]
                ]
              end
              puts table.render(:unicode, padding: [0, 1])

              puts pastel.dim("\nShowing first 20 chats") if chats.size > 20
            else
              puts pastel.yellow("\nNo chats found or unable to parse response")
              puts "Response: #{response.data.inspect}"
            end
          else
            puts pastel.red("\nFailed to list chats")
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def get_messages
        app.send(:clear_screen)
        app.send(:show_header, 'Chat Messages')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }
        limit = prompt.ask('Number of messages:', default: '20', convert: :int)

        spinner = TTY::Spinner.new("[:spinner] Loading messages...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.messages(chat_id: chat_id, limit: limit)
          spinner.stop

          if response.success?
            messages = response.data[:messages] || response.data

            if messages.is_a?(Array) && messages.any?
              puts pastel.green("\nMessages:\n")

              messages.each do |msg|
                sender = msg[:fromMe] ? pastel.blue('You') : pastel.green(msg[:pushName] || msg[:from] || 'Unknown')
                content = msg[:body] || msg[:message] || msg[:caption] || '[Media]'
                timestamp = msg[:timestamp] || msg[:t]

                time_str = if timestamp
                             Time.at(timestamp.to_i).strftime('%H:%M')
                           else
                             '--:--'
                           end

                puts "#{pastel.dim("[#{time_str}]")} #{sender}: #{content[0..60]}"
              end
            else
              puts pastel.yellow("\nNo messages found")
              puts "Response: #{response.data.inspect}"
            end
          else
            puts pastel.red("\nFailed to get messages")
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def mark_as_read
        app.send(:clear_screen)
        app.send(:show_header, 'Mark as Read')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Marking as read...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.mark_as_read(chat_id: chat_id)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def archive_chat
        app.send(:clear_screen)
        app.send(:show_header, 'Archive Chat')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Archiving...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.archive(chat_id: chat_id)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def unarchive_chat
        app.send(:clear_screen)
        app.send(:show_header, 'Unarchive Chat')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Unarchiving...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.unarchive(chat_id: chat_id)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def pin_chat
        app.send(:clear_screen)
        app.send(:show_header, 'Pin Chat')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Pinning...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.pin(chat_id: chat_id)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def unpin_chat
        app.send(:clear_screen)
        app.send(:show_header, 'Unpin Chat')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Unpinning...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.unpin(chat_id: chat_id)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def delete_chat
        app.send(:clear_screen)
        app.send(:show_header, 'Delete Chat')

        chat_id = prompt.ask('Chat ID (number or JID):') { |q| q.required true }

        confirm = prompt.yes?(pastel.red("Are you sure you want to delete this chat? This cannot be undone!"))
        return unless confirm

        spinner = TTY::Spinner.new("[:spinner] Deleting...", format: :dots)
        spinner.auto_spin

        begin
          response = client.chat.delete(chat_id: chat_id)
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
