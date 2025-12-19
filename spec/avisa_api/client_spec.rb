# frozen_string_literal: true

RSpec.describe AvisaApi::Client do
  let(:token) { 'test_token_123' }
  let(:client) { described_class.new(token: token) }

  describe '#initialize' do
    context 'with token' do
      it 'creates client successfully' do
        expect(client).to be_a(AvisaApi::Client)
        expect(client.config.token).to eq(token)
      end
    end

    context 'without token' do
      it 'raises ArgumentError' do
        expect { described_class.new }.to raise_error(ArgumentError, 'Token is required')
      end
    end

    context 'with custom configuration' do
      let(:custom_url) { 'https://custom.api.com' }
      let(:client) { described_class.new(token: token, base_url: custom_url, timeout: 60) }

      it 'uses custom values' do
        # Configuration normalizes base_url to always have trailing slash
        expect(client.config.base_url).to eq("#{custom_url}/")
        expect(client.config.timeout).to eq(60)
      end
    end

    context 'with global configuration' do
      before do
        AvisaApi.configure do |config|
          config.token = 'global_token'
          config.base_url = 'https://global.api.com'
        end
      end

      it 'uses global configuration when not overridden' do
        client = described_class.new
        expect(client.config.token).to eq('global_token')
        # Configuration normalizes base_url to always have trailing slash
        expect(client.config.base_url).to eq('https://global.api.com/')
      end

      it 'overrides global configuration with local values' do
        client = described_class.new(token: 'local_token')
        expect(client.config.token).to eq('local_token')
        # Configuration normalizes base_url to always have trailing slash
        expect(client.config.base_url).to eq('https://global.api.com/')
      end
    end
  end

  describe 'API modules' do
    it 'provides messages module' do
      expect(client.messages).to be_a(AvisaApi::Api::Messages)
    end

    it 'provides instance module' do
      expect(client.instance).to be_a(AvisaApi::Api::Instance)
    end

    it 'provides webhook module' do
      expect(client.webhook).to be_a(AvisaApi::Api::Webhook)
    end

    it 'provides validation module' do
      expect(client.validation).to be_a(AvisaApi::Api::Validation)
    end

    it 'provides groups module' do
      expect(client.groups).to be_a(AvisaApi::Api::Groups)
    end

    it 'provides chat module' do
      expect(client.chat).to be_a(AvisaApi::Api::Chat)
    end

    it 'memoizes modules' do
      expect(client.messages).to be(client.messages)
    end
  end

  describe 'HTTP methods' do
    describe '#get' do
      it 'performs GET request' do
        stub_avisa_api(:get, '/test', response_body: { success: true })

        response = client.get('/test')

        expect(response).to be_success
        expect(response.data[:success]).to be(true)
      end
    end

    describe '#post' do
      it 'performs POST request' do
        base_url = AvisaApi::Configuration::DEFAULT_BASE_URL.chomp('/')
        stub_request(:post, "#{base_url}/test")
          .with(body: { number: '123' }.to_json)
          .to_return(status: 200, body: { id: 'msg_1' }.to_json, headers: { 'Content-Type' => 'application/json' })

        response = client.post('/test', { number: '123' })

        expect(response).to be_success
        expect(response.data[:id]).to eq('msg_1')
      end
    end

    describe '#delete' do
      it 'performs DELETE request' do
        stub_avisa_api(:delete, '/test', response_body: { deleted: true })

        response = client.delete('/test')

        expect(response).to be_success
      end
    end
  end

  describe 'error handling' do
    it 'raises AuthenticationError on 401' do
      stub_avisa_api(:get, '/test', status: 401, response_body: { error: 'Unauthorized' })

      expect { client.get('/test') }.to raise_error(AvisaApi::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_avisa_api(:get, '/test', status: 429, response_body: { error: 'Rate limit' })

      expect { client.get('/test') }.to raise_error(AvisaApi::RateLimitError)
    end

    it 'raises NotFoundError on 404' do
      stub_avisa_api(:get, '/test', status: 404, response_body: { error: 'Not found' })

      expect { client.get('/test') }.to raise_error(AvisaApi::NotFoundError)
    end

    it 'raises ServerError on 500' do
      stub_avisa_api(:get, '/test', status: 500, response_body: { error: 'Server error' })

      expect { client.get('/test') }.to raise_error(AvisaApi::ServerError)
    end
  end
end
