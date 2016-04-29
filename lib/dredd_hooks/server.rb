require 'socket'

require 'dredd_hooks/server/buffer'
require 'dredd_hooks/server/events_handler'

module DreddHooks

  # The hooks worker server
  class Server

    attr_reader :events_handler
    private :events_handler

    HOST = '127.0.0.1'
    PORT = 61321
    MESSAGE_DELIMITER = "\n"

    def initialize
      @server = TCPServer.new HOST, PORT
      @buffer = Buffer.new(MESSAGE_DELIMITER)
      @events_handler = EventsHandler.new
    end

    def run
      loop do
        #Thread.abort_on_exception=true
        client = @server.accept
        STDERR.puts 'Dredd connected to Ruby Dredd hooks worker'
        @buffer.flush!
        while (data = client.recv(10))
          @buffer << data
          if @buffer.any_message?
            messages = @buffer.unshift_messages

            messages.each do |message|
              process_message(message, client)
            end
          end
        end
        client.close
      end
    end

    private

      def process_message(message, client)
        event = message['event']
        transaction = message['data']

        transaction = events_handler.handle(event, transaction)

        to_send = {
          "uuid" => message['uuid'],
          "event" => event,
          "data" => transaction
        }.to_json
        client.puts to_send + "\n"
      end

  end
end

