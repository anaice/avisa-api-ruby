# frozen_string_literal: true

require 'base64'

module AvisaApi
  module Tui
    class MessagesMenu
      attr_reader :app, :prompt, :pastel, :client
      attr_accessor :last_phone_number

      def initialize(app)
        @app = app
        @prompt = app.prompt
        @pastel = app.pastel
        @client = app.client
        @last_phone_number = nil
      end

      def show
        loop do
          app.send(:clear_screen)
          app.send(:show_header, 'Messages')

          choice = prompt.select('Select message type:', cycle: true) do |menu|
            menu.choice 'Send Text Message', :text
            menu.choice 'Send Image', :image
            menu.choice 'Send Document', :document
            menu.choice 'Send Audio', :audio
            menu.choice 'Send Video', :video
            menu.choice 'Send Location', :location
            menu.choice 'Send Link Preview', :preview
            menu.choice 'React to Message', :react
            menu.choice 'Delete Message', :delete
            menu.choice pastel.dim('Back'), :back
          end

          break if choice == :back

          case choice
          when :text then send_text
          when :image then send_image
          when :document then send_document
          when :audio then send_audio
          when :video then send_video
          when :location then send_location
          when :preview then send_preview
          when :react then react_to_message
          when :delete then delete_message
          end
        end
      end

      private

      def send_text
        app.send(:clear_screen)
        app.send(:show_header, 'Send Text Message')

        number = ask_phone_number
        message = prompt.ask('Message:') do |q|
          q.required true
        end

        send_with_spinner do
          client.messages.send_text(number: number, message: message)
        end
      end

      def send_image
        app.send(:clear_screen)
        app.send(:show_header, 'Send Image')

        number = ask_phone_number

        source = prompt.select('Image source:') do |menu|
          menu.choice 'URL', :url
          menu.choice 'Base64', :base64
          menu.choice 'File path', :file
        end

        case source
        when :url
          url = prompt.ask('Image URL:') { |q| q.required true }
          file_name = prompt.ask('Filename (e.g., image.jpg):') { |q| q.required true }
          caption = prompt.ask('Caption (optional):')
          send_with_spinner do
            client.messages.send_media(number: number, url: url, caption: caption, media_type: 'image', file_name: file_name)
          end
        when :base64
          base64 = prompt.ask('Base64 data (with data:image/...;base64, prefix):') { |q| q.required true }
          message = prompt.ask('Caption (optional):')
          send_with_spinner do
            client.messages.send_image(number: number, base64: base64, message: message)
          end
        when :file
          path = prompt.ask('File path:') { |q| q.required true }
          if File.exist?(path)
            ext = File.extname(path).downcase.delete('.')
            mime_type = case ext
                        when 'jpg', 'jpeg' then 'image/jpeg'
                        when 'png' then 'image/png'
                        when 'gif' then 'image/gif'
                        when 'webp' then 'image/webp'
                        else 'image/jpeg'
                        end
            base64_data = Base64.strict_encode64(File.binread(path))
            base64 = "data:#{mime_type};base64,#{base64_data}"
            message = prompt.ask('Caption (optional):')
            send_with_spinner do
              client.messages.send_image(number: number, base64: base64, message: message)
            end
          else
            puts pastel.red("File not found: #{path}")
            prompt.keypress("\nPress any key to continue...")
          end
        end
      end

      def send_document
        app.send(:clear_screen)
        app.send(:show_header, 'Send Document')

        number = ask_phone_number
        filename = prompt.ask('Filename (e.g., report.pdf):') { |q| q.required true }

        source = prompt.select('Document source:') do |menu|
          menu.choice 'URL', :url
          menu.choice 'Base64', :base64
          menu.choice 'File path', :file
        end

        case source
        when :url
          url = prompt.ask('Document URL:') { |q| q.required true }
          send_with_spinner do
            client.messages.send_media(number: number, url: url, media_type: 'document', file_name: filename)
          end
        when :base64
          base64 = prompt.ask('Base64 data (with data:application/...;base64, prefix):') { |q| q.required true }
          send_with_spinner do
            client.messages.send_document(number: number, base64: base64, filename: filename)
          end
        when :file
          path = prompt.ask('File path:') { |q| q.required true }
          if File.exist?(path)
            ext = File.extname(path).downcase.delete('.')
            mime_type = case ext
                        when 'pdf' then 'application/pdf'
                        when 'doc' then 'application/msword'
                        when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                        when 'xls' then 'application/vnd.ms-excel'
                        when 'xlsx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                        when 'txt' then 'text/plain'
                        when 'csv' then 'text/csv'
                        when 'zip' then 'application/zip'
                        else 'application/octet-stream'
                        end
            base64_data = Base64.strict_encode64(File.binread(path))
            base64 = "data:#{mime_type};base64,#{base64_data}"
            send_with_spinner do
              client.messages.send_document(number: number, base64: base64, filename: filename)
            end
          else
            puts pastel.red("File not found: #{path}")
            prompt.keypress("\nPress any key to continue...")
          end
        end
      end

      def send_audio
        app.send(:clear_screen)
        app.send(:show_header, 'Send Audio')

        number = ask_phone_number

        source = prompt.select('Audio source:') do |menu|
          menu.choice 'URL', :url
          menu.choice 'Base64', :base64
          menu.choice 'File path (.ogg)', :file
        end

        case source
        when :url
          url = prompt.ask('Audio URL:') { |q| q.required true }
          file_name = prompt.ask('Filename (e.g., audio.ogg):') { |q| q.required true }
          send_with_spinner do
            client.messages.send_media(number: number, url: url, media_type: 'audio', file_name: file_name)
          end
        when :base64
          base64 = prompt.ask('Base64 data (plain, without data: prefix):') { |q| q.required true }
          send_with_spinner do
            client.messages.send_audio(number: number, base64: base64)
          end
        when :file
          path = prompt.ask('Audio file path (.ogg):') { |q| q.required true }
          if File.exist?(path)
            base64 = Base64.strict_encode64(File.binread(path))
            send_with_spinner do
              client.messages.send_audio(number: number, base64: base64)
            end
          else
            puts pastel.red("File not found: #{path}")
            prompt.keypress("\nPress any key to continue...")
          end
        end
      end

      def send_video
        app.send(:clear_screen)
        app.send(:show_header, 'Send Video')

        number = ask_phone_number
        caption = prompt.ask('Caption (optional):')

        source = prompt.select('Video source:') do |menu|
          menu.choice 'URL', :url
          menu.choice 'Base64', :base64
        end

        case source
        when :url
          url = prompt.ask('Video URL:') { |q| q.required true }
          file_name = prompt.ask('Filename (e.g., video.mp4):') { |q| q.required true }
          send_with_spinner do
            client.messages.send_media(number: number, url: url, caption: caption, media_type: 'video', file_name: file_name)
          end
        when :base64
          puts pastel.yellow("Video via base64 is not supported. Please use URL.")
          prompt.keypress("\nPress any key to continue...")
        end
      end

      def send_location
        app.send(:clear_screen)
        app.send(:show_header, 'Send Location')

        number = ask_phone_number
        jid = format_jid(number)
        latitude = prompt.ask('Latitude:') { |q| q.required true; q.convert :float }
        longitude = prompt.ask('Longitude:') { |q| q.required true; q.convert :float }
        name = prompt.ask('Location name (optional):')

        send_with_spinner do
          client.messages.send_location(
            number: jid,
            latitude: latitude,
            longitude: longitude,
            name: name
          )
        end
      end

      def send_preview
        app.send(:clear_screen)
        app.send(:show_header, 'Send Link Preview')

        number = ask_phone_number
        message = prompt.ask('Message (text with the link):') { |q| q.required true }
        url = prompt.ask('URL to preview:') { |q| q.required true }
        title = prompt.ask('Custom title (optional):')
        description = prompt.ask('Custom description (optional):')

        source = prompt.select('Preview image source:') do |menu|
          menu.choice 'Base64', :base64
          menu.choice 'File path', :file
        end

        case source
        when :base64
          image = prompt.ask('Base64 image data:') { |q| q.required true }
          send_preview_request(number, message, url, image, title, description)
        when :file
          path = prompt.ask('Image file path:') { |q| q.required true }
          if File.exist?(path)
            ext = File.extname(path).downcase.delete('.')
            mime_type = case ext
                        when 'jpg', 'jpeg' then 'image/jpeg'
                        when 'png' then 'image/png'
                        when 'gif' then 'image/gif'
                        when 'webp' then 'image/webp'
                        else 'image/jpeg'
                        end
            base64_data = Base64.strict_encode64(File.binread(path))
            image = "data:#{mime_type};base64,#{base64_data}"
            send_preview_request(number, message, url, image, title, description)
          else
            puts pastel.red("File not found: #{path}")
            prompt.keypress("\nPress any key to continue...")
          end
        end
      end

      def send_preview_request(number, message, url, image, title, description)
        send_with_spinner do
          client.messages.send_preview(
            number: number,
            message: message,
            url: url,
            image: image,
            title: title.to_s.empty? ? nil : title,
            description: description.to_s.empty? ? nil : description
          )
        end
      end

      def react_to_message
        app.send(:clear_screen)
        app.send(:show_header, 'React to Message')

        number = ask_phone_number
        jid = format_jid(number)
        message_id = prompt.ask('Message ID to react to:') { |q| q.required true }
        emoji = prompt.ask('Emoji reaction:') { |q| q.required true }

        send_with_spinner do
          client.messages.react(number: jid, id: message_id, emoji: emoji)
        end
      end

      def delete_message
        app.send(:clear_screen)
        app.send(:show_header, 'Delete Message')

        number = ask_phone_number
        message_id = prompt.ask('Message ID to delete:') { |q| q.required true }

        confirm = prompt.yes?("Are you sure you want to delete message #{message_id}?")
        return unless confirm

        send_with_spinner do
          client.messages.delete_message(number: number, id: message_id)
        end
      end

      def ask_phone_number
        hint = last_phone_number ? " [#{last_phone_number}]" : ''
        number = prompt.ask("Phone number#{hint}:", default: last_phone_number) do |q|
          q.required true
          q.validate(/\A\d{10,15}\z/, 'Enter a valid phone number (10-15 digits)')
        end
        @last_phone_number = number
        number
      end

      def format_jid(number)
        return number if number.include?('@')

        "#{number}@s.whatsapp.net"
      end

      def send_with_spinner(&block)
        spinner = TTY::Spinner.new("[:spinner] Sending...", format: :dots)
        spinner.auto_spin

        begin
          response = block.call
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
