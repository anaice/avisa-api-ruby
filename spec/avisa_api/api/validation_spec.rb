# frozen_string_literal: true

RSpec.describe AvisaApi::Api::Validation do
  let(:client) { AvisaApi::Client.new(token: 'test_token') }
  let(:validation) { client.validation }

  describe '#check_number' do
    it 'checks if number has WhatsApp' do
      stub_request(:post, 'https://www.avisaapi.com.br/api/actions/checknumber')
        .with(body: { number: '51999999999' }.to_json)
        .to_return(
          status: 200,
          body: { exists: true, jid: '5551999999999@s.whatsapp.net' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = validation.check_number(number: '51999999999')

      expect(response).to be_success
      expect(response.data[:exists]).to be(true)
      expect(response.data[:jid]).to eq('5551999999999@s.whatsapp.net')
    end

    it 'returns false for non-WhatsApp number' do
      stub_request(:post, 'https://www.avisaapi.com.br/api/actions/checknumber')
        .with(body: { number: '51999999998' }.to_json)
        .to_return(
          status: 200,
          body: { exists: false }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = validation.check_number(number: '51999999998')

      expect(response).to be_success
      expect(response.data[:exists]).to be(false)
    end
  end

  describe '#check_number_international' do
    it 'checks international number' do
      stub_request(:post, 'https://www.avisaapi.com.br/api/actions/checknumberinternational')
        .with(body: { number: '+5551999999999' }.to_json)
        .to_return(
          status: 200,
          body: { exists: true }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = validation.check_number_international(number: '+5551999999999')

      expect(response).to be_success
      expect(response.data[:exists]).to be(true)
    end
  end
end
