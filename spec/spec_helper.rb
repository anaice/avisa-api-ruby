# frozen_string_literal: true

require 'webmock/rspec'
require 'avisa_api'

# Configure WebMock to disable all real connections
WebMock.disable_net_connect!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    AvisaApi.reset_configuration!
  end
end

def stub_avisa_api(method, path, response_body: {}, status: 200)
  # Remove leading slash from path if base_url has trailing slash
  base_url = AvisaApi::Configuration::DEFAULT_BASE_URL.chomp('/')
  normalized_path = path.start_with?('/') ? path : "/#{path}"
  full_url = "#{base_url}#{normalized_path}"

  stub_request(method, full_url)
    .to_return(
      status: status,
      body: response_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end
