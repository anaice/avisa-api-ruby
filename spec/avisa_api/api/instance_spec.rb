# frozen_string_literal: true

RSpec.describe AvisaApi::Api::Instance do
  let(:client) { AvisaApi::Client.new(token: 'test_token') }
  let(:instance) { client.instance }

  describe '#qr_code' do
    it 'returns QR code' do
      stub_avisa_api(:get, '/instance/qr', response_body: { qr: 'base64_qr_code' })

      response = instance.qr_code

      expect(response).to be_success
      expect(response.data[:qr]).to eq('base64_qr_code')
    end
  end

  describe '#status' do
    it 'returns instance status' do
      stub_avisa_api(:get, '/instance/status', response_body: { LoggedIn: true, phone: '5511999999999' })

      response = instance.status

      expect(response).to be_success
      expect(response.data[:LoggedIn]).to be(true)
      expect(response.data[:phone]).to eq('5511999999999')
    end
  end

  describe '#connected?' do
    it 'returns true when logged in' do
      stub_avisa_api(:get, '/instance/status', response_body: { LoggedIn: true })

      expect(instance.connected?).to be(true)
    end

    it 'returns false when not logged in' do
      stub_avisa_api(:get, '/instance/status', response_body: { LoggedIn: false })

      expect(instance.connected?).to be(false)
    end
  end
end
