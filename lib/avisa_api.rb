# frozen_string_literal: true

require_relative 'avisa_api/version'
require_relative 'avisa_api/configuration'
require_relative 'avisa_api/error'
require_relative 'avisa_api/response'
require_relative 'avisa_api/client'

module AvisaApi
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def reset_configuration!
      self.configuration = Configuration.new
    end
  end
end
