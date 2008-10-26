require 'adhearsion/voip/asterisk/manager_interface/ami_parser'

module Adhearsion
  module VoIP
    module Asterisk
      
      class AMI
        def initialize
          raise "Sorry, this AMI object has been deprecated. Please see http://docs.adhearsion.com/Asterisk_Manager_Interface for documentation on the new way of handling AMI. This new version is much better and should not require an enormous migration on your part."
        end
      end
      
      class ManagerInterface
          
        module Abstractions
          
          def login!
            begin
              @action_sock = TCPSocket.new host, port
            rescue Errno::ECONNREFUSED => refusal_error
              raise Errno::ECONNREFUSED, "Could not connect with AMI to Asterisk server at #{host}:#{port}. " +
                                         "Is enabled set to 'yes' in manager.conf?"
            end

            begin
              execute_ami_command! :login, :username => user, :secret => password, :events => (events_enabled? ? "On" : "Off")
            rescue ActionError
              raise AuthenticationFailedException, "Invalid AMI username/password! Check manager.conf."
            else

            end
          end
          
          def originate(options={})
            options = options.clone
            options[:callerid] = options.delete :caller_id if options.has_key? :caller_id
            execute_ami_command! :originate, options
          end

          def ping
            execute_ami_command! :ping
          end

          # An introduction connects two endpoints together. The first argument is
          # the first person the PBX will call. When she's picked up, Asterisk will
          # play ringing while the second person is being dialed.
          #
          # The first argument is the person called first. Pass this as a canonical
          # IAX2/server/user type argument. Destination takes the same format, but
          # comma-separated Dial() arguments can be optionally passed after the
          # technology.
          #
          # TODO: Provide an example when this works.
          def introduce(caller, callee, opts={})
            dial_args  = callee
            dial_args += "|#{opts[:options]}" if opts[:options]
            call_and_exec caller, "Dial", :args => dial_args, :caller_id => opts[:caller_id]
          end

          def hangup(channel)
            execute_ami_command! "hangup", :channel => channel
          end

          def call_and_exec(channel, app, opts={})
            args = { :channel => channel, :application => app }
            args[:caller_id] = opts[:caller_id] if opts[:caller_id]
            args[:data] = opts[:args] if opts[:args]
            originate args
          end

          def call_into_context(channel, context, options={})
            args = {:channel => channel, :context => context}
            args[:priority] = options[:priority] || 1
            args[:extension] = options[:extension] if options[:extension]
            args[:caller_id] = options[:caller_id] if options[:caller_id]
            if options[:variables] && options[:variables].kind_of?(Hash)
              args[:variable] = options[:variables].map {|pair| pair.join('=')}.join('|')
            end
            originate args
          end

        end
        
        include Abstractions
        
        DEFAULT_SETTINGS = {
          :hostname => "localhost",
          :port     => 5038,
          :username => "admin",
          :password => "secret"
          :events   => true
        }.freeze unless defined? DEFAULT_SETTINGS
        
        SUPPORTED_EVENTMACHINE_CALLBACKS = [
          :post_init, :receive_data, :unbind
        ].freeze unless defined? SUPPORTED_EVENTMACHINE_CALLBACKS
        
        attr_reader *DEFAULT_SETTINGS.keys
        
        ##
        # Creates a new Asterisk Manager Interface connection and exposes certain methods to control it.
        #
        # @param [Hash] options Supply
        #
        def initialize(options={})
          options = DEFAULT_SETTINGS.merge options
          @hostname,@port,@username,@password,@events = options.values_at :hostname, :port, :username, :password, :events
          @message_queue = Queue.new
          @action_parser = ActionManagerInterfaceSocket.new(self)
        end
        
        ##
        # 
        #
        # @return [EventMachine::Connection]
        def establish_connection
          EventMachine.connect @hostname, @port do |connection|
            SUPPORTED_EVENTMACHINE_CALLBACKS.each do |callback_name|
              connection.send(callback_name, &method(callback_name))
            end
          end
        end
        
        def connect!
          disconnect!
          start_event_thread! if events_enabled?
          login! host, user, password, port, events_enabled?
        end
        
        def disconnect!
          action_sock.close if action_sock && !action_sock.closed?
          event_thread.kill if event_thread
          scanner.stop if scanner
        end
        
        def events_enabled?
          @events_enabled
        end
        
        def dynamic
          # TODO: Return an object which responds to method_missing
        end
        
        def post_init
          login!
        end
        
        def receive_data(data)
          @parser << data
        end
        
        protected
        
        ##
        # Sends an AMI command by converting the headers directly to key/value pairs with no coercion.
        #
        # @param [Hash] headers The series of key/value pairs to send
        def send_command(headers)
          # Reconnect if disconnected
          # QUEUE messages to write!
          headers.inject("") do |string_command,(key,value)|
            string_command << "#{key}: #{value}\r\n"
          end + "\r\n"
        end
        
        class AuthenticationFailedException < Exception; end
        class ActionError < RuntimeError; end
      end
    end
  end
end