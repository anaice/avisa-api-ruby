# frozen_string_literal: true

require 'tty-prompt'
require 'tty-table'
require 'tty-spinner'
require 'tty-box'
require 'pastel'

require_relative 'tui/app'
require_relative 'tui/messages_menu'
require_relative 'tui/instance_menu'
require_relative 'tui/groups_menu'
require_relative 'tui/webhook_menu'
require_relative 'tui/chat_menu'

module AvisaApi
  module Tui
    class << self
      def start
        App.new.run
      end
    end
  end
end
