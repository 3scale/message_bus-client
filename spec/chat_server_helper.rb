message_bus_path = Bundler.rubygems.find_name('message_bus').first.full_gem_path
chat_example_path = File.join(message_bus_path, 'examples/chat')

# Override the load path so that the message_bus library loads before us. The middleware uses a
# MessageBus::Client class as well, with a different use case from ours.
$LOAD_PATH.unshift File.expand_path('lib', message_bus_path)

# Use the in-memory backend since this is for testing.
require 'message_bus'
MessageBus.config[:backend] = :memory

# Run the Chat Sinatra app.
require File.join(chat_example_path, 'chat')

RSpec.configure do |config|
  config.around(:all) do |example|
    Thread.abort_on_exception = true
    Chat.set :port, 9292
    server = Thread.new { Chat.run! }

    retries = 0
    begin
      Socket.tcp('localhost', 9292, connect_timeout: 1)
    rescue Errno::ECONNREFUSED
      if (retries = retries.succ) < 10
        warn 'waiting for chat server to start on localhost:9292'
        sleep 1
        retry
      end
    end

    example.run

    at_exit do
      Chat.quit!
      server.kill
    end
  end
end
