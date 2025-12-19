# frozen_string_literal: true

require_relative 'lib/avisa_api/version'

Gem::Specification.new do |spec|
  spec.name = 'avisa-api-ruby'
  spec.version = AvisaApi::VERSION
  spec.authors = ['Rafael Anaice']

  spec.summary = 'Cliente Ruby para integração com AvisaAPI WhatsApp'
  spec.description = 'Gem Ruby para integração com AvisaAPI (avisaapi.com.br) - API de mensagens WhatsApp. ' \
                     'Envie mensagens de texto, mídia, documentos, gerencie grupos, webhooks e mais.'
  spec.homepage = 'https://github.com/anaice/avisa-api-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github .circleci appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '>= 1.0', '< 3.0'
  spec.add_dependency 'faraday-retry', '~> 2.0'

  # TUI dependencies
  spec.add_dependency 'tty-prompt', '~> 0.23'
  spec.add_dependency 'tty-table', '~> 0.12'
  spec.add_dependency 'tty-spinner', '~> 0.9'
  spec.add_dependency 'tty-box', '~> 0.7'
  spec.add_dependency 'pastel', '~> 0.8'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'yard', '~> 0.9'
end
