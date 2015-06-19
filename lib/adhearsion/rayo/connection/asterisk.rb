# encoding: utf-8

require 'ruby_ami'
require 'adhearsion/rayo/connection/generic_connection'
require 'adhearsion/translator'

module Adhearsion
  module Rayo
    module Connection
      class Asterisk < GenericConnection
        attr_reader :ami_client, :translator
        attr_accessor :event_handler

        def initialize(options = {})
          @stream_options = options.values_at(:host, :port, :username, :password)
          @ami_client = new_ami_stream
          @translator = Translator::Asterisk.new @ami_client, self
          super()
        end

        def run
          start_ami_client
          raise DisconnectedError
        end

        def stop
          translator.terminate
          ami_client.terminate
        end

        def write(command, options)
          translator.async.execute_command command, options
        end

        def send_message(*args)
          translator.send_message *args
        end

        def handle_event(event)
          event_handler.call event
        end

        def new_ami_stream
          stream = RubyAMI::Stream.new(*@stream_options, ->(event) { translator.async.handle_ami_event event }, logger)
          client = (ami_client || RubyAMIStreamProxy.new(stream))
          client.stream = stream
          client
        end

        def start_ami_client
          @ami_client = new_ami_stream unless ami_client.alive?
          ami_client.async.run
          Celluloid::Actor.join(ami_client)
        end

        def new_call_uri
          Adhearsion.new_uuid
        end

        class RubyAMIStreamProxy
          attr_accessor :stream

          def initialize(ami)
            @stream = ami
          end

          def method_missing(method, *args, &block)
            stream.__send__(method, *args, &block)
          end
        end
      end
    end
  end
end
