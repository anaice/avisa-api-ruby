# frozen_string_literal: true

RSpec.describe AvisaApi do
  it 'has a version number' do
    expect(AvisaApi::VERSION).not_to be_nil
    expect(AvisaApi::VERSION).to eq('0.1.0')
  end

  describe '.configure' do
    it 'allows configuration via block' do
      AvisaApi.configure do |config|
        config.token = 'my_token'
        config.base_url = 'https://custom.api.com'
        config.timeout = 60
      end

      expect(AvisaApi.configuration.token).to eq('my_token')
      expect(AvisaApi.configuration.base_url).to eq('https://custom.api.com')
      expect(AvisaApi.configuration.timeout).to eq(60)
    end
  end

  describe '.reset_configuration!' do
    it 'resets configuration to defaults' do
      AvisaApi.configure { |c| c.token = 'test' }
      AvisaApi.reset_configuration!

      expect(AvisaApi.configuration.token).to be_nil
      expect(AvisaApi.configuration.base_url).to eq(AvisaApi::Configuration::DEFAULT_BASE_URL)
    end
  end
end
