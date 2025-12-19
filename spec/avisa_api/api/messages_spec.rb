# frozen_string_literal: true

RSpec.describe AvisaApi::Api::Messages do
  let(:client) { AvisaApi::Client.new(token: 'test_token') }
  let(:dest_number) { '5511999999999' }
  let(:messages) { client.messages }
  let(:base_url) { AvisaApi::Configuration::DEFAULT_BASE_URL.chomp('/') }

  describe '#send_text' do
    it 'sends a text message' do
      stub_request(:post, "#{base_url}/actions/sendMessage")
        .with(body: { number: dest_number, message: 'Hello!' }.to_json)
        .to_return(
          status: 200,
          body: { status: true, message: 'Message sent successfully' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = messages.send_text(number: dest_number, message: 'Hello!')

      expect(response).to be_success
      expect(response.data[:status]).to be(true)
    end

    xit 'sends message with custom id' do
      stub_request(:post, "#{base_url}/actions/sendMessage")
        .with(body: { number: dest_number, message: 'Hi', id: 'custom_id' }.to_json)
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_text(number: dest_number, message: 'Hi', id: 'custom_id')

      expect(response).to be_success
    end

    xit 'sends reply with context_info' do
      stub_request(:post, "#{base_url}actions/sendMessage")
        .with(body: hash_including('contextInfo' => { 'StanzaId' => 'orig_msg', 'Participant' => '123@s.whatsapp.net' }))
        .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_text(
        number: dest_number,
        message: 'Reply',
        context_info: { stanza_id: 'orig_msg', participant: '123@s.whatsapp.net' }
      )

      expect(response).to be_success
    end
  end

  describe '#send_image' do
    it 'sends an image with base64 and caption' do
      stub_request(:post, "#{base_url}/actions/sendImage")
        .with(body: { number: dest_number, image: 'data:image/jpeg;base64,/9j/4AAQ', message: 'My photo' }.to_json)
        .to_return(status: 200, body: { id: 'img_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_image(number: dest_number, base64: 'data:image/jpeg;base64,/9j/4AAQ', message: 'My photo')

      expect(response).to be_success
      expect(response.data[:id]).to eq('img_123')
    end

    it 'sends an image without caption' do
      stub_request(:post, "#{base_url}/actions/sendImage")
        .with(body: { number: dest_number, image: 'data:image/png;base64,iVBORw0KGgo' }.to_json)
        .to_return(status: 200, body: { id: 'img_124' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_image(number: dest_number, base64: 'data:image/png;base64,iVBORw0KGgo')

      expect(response).to be_success
    end
  end

  describe '#send_document' do
    it 'sends a document with base64' do
      stub_request(:post, "#{base_url}/actions/sendDocument")
        .with(body: { number: dest_number, document: 'data:application/pdf;base64,JVBERi0', fileName: 'invoice.pdf' }.to_json)
        .to_return(status: 200, body: { id: 'doc_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_document(number: dest_number, base64: 'data:application/pdf;base64,JVBERi0', filename: 'invoice.pdf')

      expect(response).to be_success
      expect(response.data[:id]).to eq('doc_123')
    end
  end

  describe '#send_location' do
    it 'sends a location' do
      # Note: number must include @s.whatsapp.net suffix for location
      jid = "#{dest_number}@s.whatsapp.net"
      stub_request(:post, "#{base_url}/actions/sendLocation")
        .with(body: { number: jid, latitude: -23.5505, longitude: -46.6333, name: 'Sao Paulo' }.to_json)
        .to_return(status: 200, body: { id: 'loc_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_location(
        number: jid,
        latitude: -23.5505,
        longitude: -46.6333,
        name: 'Sao Paulo'
      )

      expect(response).to be_success
    end

    it 'sends a location without name' do
      jid = "#{dest_number}@s.whatsapp.net"
      stub_request(:post, "#{base_url}/actions/sendLocation")
        .with(body: { number: jid, latitude: -23.5505, longitude: -46.6333 }.to_json)
        .to_return(status: 200, body: { id: 'loc_124' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_location(
        number: jid,
        latitude: -23.5505,
        longitude: -46.6333
      )

      expect(response).to be_success
    end
  end

  describe '#delete_message' do
    it 'deletes a message' do
      stub_request(:post, "#{base_url}/actions/deleteMessage")
        .with(body: { number: dest_number, id: 'msg_123' }.to_json)
        .to_return(status: 200, body: { deleted: true }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.delete_message(number: dest_number, id: 'msg_123')

      expect(response).to be_success
    end
  end

  describe '#react' do
    it 'reacts to a message with emoji' do
      # Note: number must include @s.whatsapp.net suffix for react
      jid = "#{dest_number}@s.whatsapp.net"
      stub_request(:post, "#{base_url}/actions/reactMessage")
        .with(body: { number: jid, id: 'msg_123', react: "\u{1F44D}" }.to_json)
        .to_return(status: 200, body: { id: 'react_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.react(number: jid, id: 'msg_123', emoji: "\u{1F44D}")

      expect(response).to be_success
    end
  end

  describe '#send_audio' do
    it 'sends audio with plain base64 (no data: prefix)' do
      stub_request(:post, "#{base_url}/actions/sendAudio")
        .with(body: { number: dest_number, audio: 'T2dnUwACAAAAAAA' }.to_json)
        .to_return(status: 200, body: { id: 'audio_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_audio(number: dest_number, base64: 'T2dnUwACAAAAAAA')

      expect(response).to be_success
      expect(response.data[:id]).to eq('audio_123')
    end
  end

  describe '#send_media' do
    it 'sends image via URL' do
      stub_request(:post, "#{base_url}/actions/sendMedia")
        .with(body: { number: dest_number, fileUrl: 'https://example.com/image.jpg', type: 'image', message: 'Caption', fileName: 'image.jpg' }.to_json)
        .to_return(status: 200, body: { id: 'media_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_media(
        number: dest_number,
        url: 'https://example.com/image.jpg',
        caption: 'Caption',
        media_type: 'image',
        file_name: 'image.jpg'
      )

      expect(response).to be_success
    end

    it 'sends document via URL' do
      stub_request(:post, "#{base_url}/actions/sendMedia")
        .with(body: { number: dest_number, fileUrl: 'https://example.com/doc.pdf', type: 'document', fileName: 'doc.pdf' }.to_json)
        .to_return(status: 200, body: { id: 'media_124' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_media(
        number: dest_number,
        url: 'https://example.com/doc.pdf',
        media_type: 'document',
        file_name: 'doc.pdf'
      )

      expect(response).to be_success
    end
  end

  describe '#send_preview' do
    it 'sends a link preview with image' do
      stub_request(:post, "#{base_url}/actions/sendPreview")
        .with(body: {
          number: dest_number,
          message: 'Check this: https://example.com',
          urlSite: 'https://example.com',
          image: 'data:image/png;base64,iVBORw0KGgo',
          title: 'Example',
          description: 'An example site'
        }.to_json)
        .to_return(status: 200, body: { id: 'preview_123' }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = messages.send_preview(
        number: dest_number,
        message: 'Check this: https://example.com',
        url: 'https://example.com',
        image: 'data:image/png;base64,iVBORw0KGgo',
        title: 'Example',
        description: 'An example site'
      )

      expect(response).to be_success
      expect(response.data[:id]).to eq('preview_123')
    end
  end
end
