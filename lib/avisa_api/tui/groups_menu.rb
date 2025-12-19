# frozen_string_literal: true

module AvisaApi
  module Tui
    class GroupsMenu
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
          app.send(:show_header, 'Groups')

          choice = prompt.select('Select option:', cycle: true) do |menu|
            menu.choice 'List Groups', :list
            menu.choice 'Create Group', :create
            menu.choice 'Get Group Info', :info
            menu.choice 'Get Invite Link', :invite_link
            menu.choice 'Add Participant', :add_participant
            menu.choice 'Remove Participant', :remove_participant
            menu.choice 'Leave Group', :leave
            menu.choice pastel.dim('Back'), :back
          end

          break if choice == :back

          case choice
          when :list then list_groups
          when :create then create_group
          when :info then get_group_info
          when :invite_link then get_invite_link
          when :add_participant then add_participant
          when :remove_participant then remove_participant
          when :leave then leave_group
          end
        end
      end

      private

      def list_groups
        app.send(:clear_screen)
        app.send(:show_header, 'List Groups')

        spinner = TTY::Spinner.new("[:spinner] Loading groups...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.list
          spinner.stop

          if response.success?
            groups = response.data[:groups] || response.data

            if groups.is_a?(Array) && groups.any?
              puts pastel.green("\nFound #{groups.size} group(s):\n")

              table = TTY::Table.new(header: ['Name', 'ID', 'Participants'])
              groups.each do |group|
                table << [
                  group[:name] || group[:subject] || 'N/A',
                  group[:id] || group[:jid] || 'N/A',
                  group[:participants]&.size || group[:size] || 'N/A'
                ]
              end
              puts table.render(:unicode, padding: [0, 1])
            else
              puts pastel.yellow("\nNo groups found or unable to parse response")
              puts "Response: #{response.data.inspect}"
            end
          else
            puts pastel.red("\nFailed to list groups")
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def create_group
        app.send(:clear_screen)
        app.send(:show_header, 'Create Group')

        name = prompt.ask('Group name:') { |q| q.required true }

        participants = []
        loop do
          participant = prompt.ask('Add participant number (or press Enter to finish):')
          break if participant.nil? || participant.empty?
          participants << participant
        end

        if participants.empty?
          puts pastel.yellow("At least one participant is required")
          prompt.keypress("\nPress any key to continue...")
          return
        end

        spinner = TTY::Spinner.new("[:spinner] Creating group...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.create(name: name, participants: participants)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def get_group_info
        app.send(:clear_screen)
        app.send(:show_header, 'Group Info')

        group_id = prompt.ask('Group ID (JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Loading group info...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.info(group_id: group_id)
          spinner.stop

          if response.success?
            data = response.data
            puts pastel.green("\nGroup Information:")
            puts

            if data.is_a?(Hash)
              table = TTY::Table.new do |t|
                data.each do |key, value|
                  display_value = value.is_a?(Array) ? value.join(', ') : value.to_s
                  t << [pastel.bold(key.to_s), display_value[0..60]]
                end
              end
              puts table.render(:unicode, padding: [0, 1])
            else
              puts data.inspect
            end
          else
            puts pastel.red("\nFailed to get group info")
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def get_invite_link
        app.send(:clear_screen)
        app.send(:show_header, 'Get Invite Link')

        group_id = prompt.ask('Group ID (JID):') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Getting invite link...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.invite_link(group_id: group_id)
          spinner.stop

          if response.success?
            link = response.data[:link] || response.data[:invite] || response.data
            puts pastel.green("\nInvite Link:")
            puts link
          else
            puts pastel.red("\nFailed to get invite link")
            puts "Body: #{response.body}"
          end
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def add_participant
        app.send(:clear_screen)
        app.send(:show_header, 'Add Participant')

        group_id = prompt.ask('Group ID (JID):') { |q| q.required true }
        participant = prompt.ask('Participant number:') { |q| q.required true }

        spinner = TTY::Spinner.new("[:spinner] Adding participant...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.add_participant(group_id: group_id, participant: participant)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def remove_participant
        app.send(:clear_screen)
        app.send(:show_header, 'Remove Participant')

        group_id = prompt.ask('Group ID (JID):') { |q| q.required true }
        participant = prompt.ask('Participant number:') { |q| q.required true }

        confirm = prompt.yes?("Are you sure you want to remove #{participant}?")
        return unless confirm

        spinner = TTY::Spinner.new("[:spinner] Removing participant...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.remove_participant(group_id: group_id, participant: participant)
          spinner.stop

          app.send(:show_response, response)
        rescue AvisaApi::Error => e
          spinner.stop
          puts pastel.red("\nError: #{e.message}")
        end

        prompt.keypress("\nPress any key to continue...")
      end

      def leave_group
        app.send(:clear_screen)
        app.send(:show_header, 'Leave Group')

        group_id = prompt.ask('Group ID (JID):') { |q| q.required true }

        confirm = prompt.yes?(pastel.red("Are you sure you want to leave this group?"))
        return unless confirm

        spinner = TTY::Spinner.new("[:spinner] Leaving group...", format: :dots)
        spinner.auto_spin

        begin
          response = client.groups.leave(group_id: group_id)
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
