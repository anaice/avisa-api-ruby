# AvisaApi Ruby Client

Ruby client for [AvisaAPI](https://avisaapi.com.br) WhatsApp integration.

WIP - Work in Progress

## Features

- Send text messages, images, documents, audio, video, and location
- Send link previews with custom images
- Manage WhatsApp instance (QR Code, status, connection)
- Configure webhooks to receive messages
- Validate WhatsApp numbers
- Manage groups
- Chat actions (typing indicator, archive)
- Interactive TUI for testing

## Installation

Add to your Gemfile:

```ruby
# From GitHub
gem 'avisa_api', github: 'anaice/avisa-api-ruby'
```

Then run:

```bash
bundle install
```

## Configuration

### Global Configuration

```ruby
AvisaApi.configure do |config|
  config.base_url = 'https://www.avisaapi.com.br/api'  # optional, this is the default
  config.token = 'your_api_token'
  config.timeout = 30  # optional, default: 30 seconds
  config.logger = Rails.logger  # optional, for debugging
end

# Then create clients without passing token
client = AvisaApi::Client.new
```

### Per-Client Configuration

```ruby
client = AvisaApi::Client.new(
  token: 'your_api_token',
  base_url: 'https://www.avisaapi.com.br/api',  # optional
  timeout: 60  # optional
)
```

### Rails Initializer

```ruby
# config/initializers/avisa_api.rb
AvisaApi.configure do |config|
  config.token = Rails.application.credentials.dig(:avisa_api, :token)
  config.base_url = Rails.application.credentials.dig(:avisa_api, :base_url) || 'https://www.avisaapi.com.br/api'
  config.logger = Rails.logger if Rails.env.development?
end
```

## Usage

### Sending Text Messages

```ruby
client = AvisaApi::Client.new(token: 'your_token')

# Send text message
response = client.messages.send_text(
  number: '5511999999999',
  message: 'Hello from Ruby!'
)

if response.success?
  puts "Message sent! ID: #{response.data[:id]}"
else
  puts "Error: #{response.error_message}"
end

# Reply to a message
client.messages.send_text(
  number: '5511999999999',
  message: 'This is a reply!',
  context_info: {
    stanza_id: 'original_message_id',
    participant: '5511888888888@s.whatsapp.net'
  }
)

# Send international message
client.messages.send_text_international(
  number: '+5511999999999',
  message: 'Hello!'
)
```

### Sending Images

```ruby
# Via URL (recommended for large files)
client.messages.send_media(
  number: '5511999999999',
  url: 'https://example.com/image.jpg',
  caption: 'Image caption',
  media_type: 'image',
  file_name: 'image.jpg'
)

# Via Base64 (include data: prefix)
image_data = Base64.strict_encode64(File.binread('photo.jpg'))
client.messages.send_image(
  number: '5511999999999',
  base64: "data:image/jpeg;base64,#{image_data}",
  message: 'Check this out!'  # caption uses 'message' field
)
```

### Sending Documents

```ruby
# Via URL
client.messages.send_media(
  number: '5511999999999',
  url: 'https://example.com/document.pdf',
  media_type: 'document',
  file_name: 'document.pdf'
)

# Via Base64 (include data: prefix)
doc_data = Base64.strict_encode64(File.binread('invoice.pdf'))
client.messages.send_document(
  number: '5511999999999',
  base64: "data:application/pdf;base64,#{doc_data}",
  filename: 'invoice.pdf'
)
```

### Sending Audio

```ruby
# Via URL
client.messages.send_media(
  number: '5511999999999',
  url: 'https://example.com/audio.ogg',
  media_type: 'audio',
  file_name: 'audio.ogg'
)

# Via Base64 (plain base64, NO data: prefix for audio)
audio_data = Base64.strict_encode64(File.binread('audio.ogg'))
client.messages.send_audio(
  number: '5511999999999',
  base64: audio_data  # plain base64, no prefix!
)
```

### Sending Video

```ruby
# Via URL only (base64 not supported for video)
client.messages.send_media(
  number: '5511999999999',
  url: 'https://example.com/video.mp4',
  caption: 'Video caption',
  media_type: 'video',
  file_name: 'video.mp4'
)
```

### Sending Location

```ruby
# Note: number must include @s.whatsapp.net suffix
client.messages.send_location(
  number: '5511999999999@s.whatsapp.net',
  latitude: -23.5505,
  longitude: -46.6333,
  name: 'São Paulo'
)
```

### Sending Link Preview

```ruby
# Image must be base64 with data: prefix
image_data = Base64.strict_encode64(File.binread('preview.png'))
client.messages.send_preview(
  number: '5511999999999',
  message: 'Check out this link: https://example.com',
  url: 'https://example.com',
  image: "data:image/png;base64,#{image_data}",
  title: 'Example Site',
  description: 'This is an example website'
)
```

### Message Actions

```ruby
# React to a message (number must include @s.whatsapp.net)
client.messages.react(
  number: '5511999999999@s.whatsapp.net',
  id: 'message_id',
  emoji: '👍'
)

# Edit a message
client.messages.edit(
  number: '5511999999999',
  id: 'message_id',
  message: 'Edited message content'
)

# Delete a message
client.messages.delete_message(
  number: '5511999999999',
  id: 'message_id'
)

# Mark messages as read
client.messages.mark_read(
  sender: '5511999999999@s.whatsapp.net',
  chat: '5511999999999@s.whatsapp.net',
  ids: ['message_id_1', 'message_id_2']
)
```

### Instance Management

```ruby
# Get QR Code for connection
response = client.instance.qr_code
puts response.data[:qr]  # Base64 QR code

# Check connection status
response = client.instance.status
puts response.data[:LoggedIn]  # true/false

# Helper method
if client.instance.connected?
  puts 'WhatsApp connected!'
end

# Disconnect instance
client.instance.delete
```

### Webhook Configuration

```ruby
# Get current webhook
response = client.webhook.show
puts response.data[:webhook]

# Set webhook URL
client.webhook.set(url: 'https://yoursite.com/api/whatsapp/webhook')

# Remove webhook
client.webhook.remove
```

### Number Validation

```ruby
# Check if number has WhatsApp
response = client.validation.check_number(number: '5511999999999')
if response.data[:exists]
  puts "WhatsApp found: #{response.data[:jid]}"
else
  puts 'Number does not have WhatsApp'
end

# International number
client.validation.check_number_international(number: '+5511999999999')
```

### Groups

```ruby
# List all groups
response = client.groups.list

# Get group info
client.groups.info(group_id: '123456789@g.us')

# Send message to group
client.groups.send_text(group_id: '123456789@g.us', message: 'Hello group!')

# Create group
client.groups.create(
  name: 'My Group',
  participants: ['5511999999999@s.whatsapp.net', '5511888888888@s.whatsapp.net']
)

# Update group name
client.groups.change_name(group_id: '123456789@g.us', name: 'New Name')

# Update group description
client.groups.change_description(group_id: '123456789@g.us', description: 'New description')

# Manage participants (add, remove, promote, demote)
client.groups.update_participants(
  group_id: '123456789@g.us',
  participants: ['5511999999999@s.whatsapp.net'],
  action: 'add'  # add, remove, promote, demote
)
```

### Chat Actions

```ruby
# Show typing indicator
client.chat.start_typing(chat: '5511999999999@s.whatsapp.net')
sleep(2)
client.chat.stop_typing(chat: '5511999999999@s.whatsapp.net')

# Show recording indicator
client.chat.start_recording(chat: '5511999999999@s.whatsapp.net')
sleep(2)
client.chat.stop_recording(chat: '5511999999999@s.whatsapp.net')

# Archive chat
client.chat.archive(chat: '5511999999999@s.whatsapp.net')
```

## Error Handling

```ruby
begin
  client.messages.send_text(number: '5511999999999', message: 'Hello!')
rescue AvisaApi::AuthenticationError => e
  puts "Invalid token: #{e.message}"
rescue AvisaApi::RateLimitError => e
  puts "Rate limit exceeded (240 req/min): #{e.message}"
rescue AvisaApi::ValidationError => e
  puts "Validation error: #{e.message}"
rescue AvisaApi::ConnectionError => e
  puts "Connection error: #{e.message}"
rescue AvisaApi::Error => e
  puts "General error: #{e.message}"
end
```

## Response Object

All API methods return a `Response` object:

```ruby
response = client.messages.send_text(number: '5511999999999', message: 'Hi')

response.success?       # true/false
response.status         # HTTP status code (200, 400, etc)
response.data           # Parsed response body (Hash with symbol keys)
response.error_message  # Error message if failed
response.headers        # Response headers
```

## Rate Limiting

AvisaAPI has a rate limit of **240 requests per minute**. The client will raise `AvisaApi::RateLimitError` when this limit is exceeded.

**Important:** Sending too many messages in a short period may trigger WhatsApp's anti-spam measures and temporarily restrict your account. Consider implementing delays between messages in production.

## Interactive TUI (Terminal User Interface)

The gem includes a full-featured interactive TUI for testing the WhatsApp API directly from your terminal.

### Running the TUI

```bash
cd avisa-api-ruby
./exe/avisa
```

Or via bundle:

```bash
bundle exec exe/avisa
```

### TUI Features

- **Messages**: Send text, images, documents, audio, video, location, link previews
- **Instance Management**: Check status, get QR code, disconnect/reconnect
- **Groups**: List, create, get info, manage participants
- **Webhooks**: View, set, and remove webhook configuration
- **Chat**: Archive chats, typing indicators
- **Validation**: Check if a number has WhatsApp
- **Phone Number Caching**: Enter a number once, reuse with Enter key

The TUI will prompt for your API token on startup and provide an interactive menu-driven interface.

## Base64 Encoding Reference

Different media types require different Base64 formats:

| Media Type | Format | Example |
|------------|--------|---------|
| Image | With prefix | `data:image/jpeg;base64,/9j/4AAQ...` |
| Document | With prefix | `data:application/pdf;base64,JVBERi...` |
| Audio | Plain base64 | `T2dnUwACAAAAAAA...` |
| Preview Image | With prefix | `data:image/png;base64,iVBORw0KGgo...` |

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/avisa_api/api/messages_spec.rb

# Interactive console
bin/console

# Interactive TUI
./exe/avisa
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Create a Pull Request

## License

MIT License. See [LICENSE](LICENSE) for details.
