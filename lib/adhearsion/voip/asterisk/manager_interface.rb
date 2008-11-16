require 'adhearsion/voip/asterisk/manager_interface/ami_lexer'

module Adhearsion
  module VoIP
    module Asterisk
      
      class AMI
        def initialize
          raise "Sorry, this AMI class has been deprecated. Please see http://docs.adhearsion.com/Asterisk_Manager_Interface for documentation on the new way of handling AMI. This new version is much better and should not require an enormous migration on your part."
        end
      end
      
      module Manager
        class ManagerInterface
          
          class << self
            
            def connect(*args)
              returning new(*args) do |connection|
                connection.connect!
              end
            end
            
            def replies_with_action_id?(name, headers={})
              name = name.to_s.downcase
              # TODO: Expand this case statement
              case name
                when "queues"
                  true
                else
                  false
              end                
            end
            
            def has_causal_events?(name, headers={})
              name = name.to_s.downcase
              case name
                when "queuestatus"
                  true
                else
                  false
              end
            end
            
          end
        
          module Abstractions
                    
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
            :host     => "localhost",
            :port     => 5038,
            :username => "admin",
            :password => "secret",
            :events   => true
          }.freeze unless defined? DEFAULT_SETTINGS
          
          attr_reader *DEFAULT_SETTINGS.keys
          
          ##
          # Creates a new Asterisk Manager Interface connection and exposes certain methods to control it. The constructor
          # takes named parameters as Symbols. Note: if the :events option is given, this library will establish a separate
          # socket for just events. Two sockets are used because some actions actually respond with events, making it very
          # complicated to differentiate between response-type events and normal events.
          #
          # @param [Hash] options Available options are :host, :port, :username, :password, and :events
          #
          def initialize(options={})
            options = parse_options options
            
            @host = options[:host]
            @username = options[:username] 
            @password = options[:password]
            @port     = options[:port]
            @events   = options[:events]
            
            @sent_messages = {}
            @sent_messages_lock = Mutex.new
            
            @actions_lexer = DelegatingAsteriskManagerInterfaceLexer.new self, \
                :message_received => :action_message_received,
                :error_received   => :action_error_received
            
            @write_queue = Queue.new
            
            if @events
              @events_lexer = DelegatingAsteriskManagerInterfaceLexer.new self, \
                  :message_received => :event_message_received,
                  :error_received   => :event_error_received 
            end
          end
          
          def action_message_received(message)
            if message.kind_of? Manager::Event
              # Trigger the return value of the waiting action id...
            elsif message.kind_of? Manager::ImmediateResponse
              # No ActionID! Release the write lock and wake up the waiter
            else
              action_id = message["ActionID"]
              corresponding_action = data_for_message_received_with_action_id action_id
              if corresponding_action
                corresponding_action.future_resource.resource = message
              else
                ahn_log.ami.error "Received an AMI message with an unrecognized ActionID!! This may be an bug! #{message.inspect}"
              end
            end
          end
          
          def action_error_received(ami_error)
            action_id = ami_error["ActionID"]
            
            sent_action_metadata = data_for_message_received_with_action_id action_id
            if sent_action_metadata
              name, headers, future_resource = sent_action_metadata.values_at :name, :headers, :future_resource
              future_resource.resource = ami_error
            else
              ahn_log.ami.error "Received an AMI error with an unrecognized ActionID!! This may be an bug! #{ami_error.inspect}"
            end
          end
          
          ##
          # Called only when this ManagerInterface is instantiated with events enabled.
          #
          def event_message_received(event)
            # TODO: convert the event name to a certain namespace.
            Events.trigger %w[asterisk events], event
          end
          
          def event_error_received(message)
            # Does this ever even occur?
          end
          
          ##
          # Called when our Ragel parser encounters some unexpected syntax from Asterisk. Anytime this is called, it should
          # be considered a bug in Adhearsion. Note: this same method is called regardless of whether the syntax error
          # happened on the actions socket or on the events socket.
          #
          def syntax_error_encountered(ignored_chunk)
            ahn_log.ami.error "ADHEARSION'S AMI PARSER ENCOUNTERED A SYNTAX ERROR! " + 
                "PLEASE REPORT THIS ON http://bugs.adhearsion.com! OFFENDING TEXT:\n#{ignored_chunk.inspect}"
          end
          
          ##
          # Must be called after instantiation. Also see ManagerInterface::connect().
          #
          # @raise [AuthenticationFailedException] if username or password are rejected
          #
          def connect!
            establish_actions_connection
            establish_events_connection if @events
            self
          end
          
          def actions_connection_established
            @actions_state = :connected
          end
          
          def actions_connection_disconnected
            @actions_state = :disconnected
          end
          
          def events_connection_established
            @events_state = :connected
          end
          
          def actions_connection_disconnected
            @events_state = :disconnected
          end
          
          def disconnect!
            # TODO: Go through all the waiting condition variables and raise an exception
            raise NotImplementedError
          end
        
          def dynamic
            # TODO: Return an object which responds to method_missing
          end
          
          def send_action_asynchronously_with_connection(connection, action)
            if action.replies_with_action_id?
              raise NotImplementedError
            else
              @write_queue << action
              action
            end
          end
          
          ##
          # Used to directly send a new action to Asterisk. Note: NEVER supply an ActionID; these are handled internally.
          #
          # @param [String, Symbol] action_name The name of the action (e.g. Originate)
          # @param [Hash] headers Other key/value pairs to send in this action. Note: don't provide an ActionID
          # @return [FutureResource] Call resource() on this object if you wish to access the response (optional). Note: if the response has not come in yet, your Thread will wait until it does.
          #
          def send_action_asynchronously(action)
            action = ManagerInterfaceAction.new(action_name, headers)
            send_action_asynchronously_with_connection(@actions_connection, action)
          end
          
          ##
          # Sends an action over the AMI connection and blocks your Thread until the response comes in. If there was an error
          # for some reason, the error will be raised as an AMIError.
          #
          # @param [String, Symbol] action_name The name of the action (e.g. Originate)
          # @param [Hash] headers Other key/value pairs to send in this action. Note: don't provide an ActionID
          # @raise [AMIError] When Asterisk can't execute this action, it sends back an Error which is converted into an AMIError object and raised. Access AMIError#message for the reported message from Asterisk.
          # @return [NormalAmiResponse, ImmediateResponse] Contains the response from Asterisk and all headers
          #
          def send_action_synchronously(*args)
            returning send_action_asynchronously(*args).response do |response|
              raise response if response.kind_of?(AMIError)
            end
          end
          
          alias send_action send_action_synchronously
        
          protected
          
          def write_loop
            loop do
              next_action = @write_queue.pop
              register_action_with_metadata next_action
              
              ahn_log.ami.debug "Sending AMI action: #{action}"
              
              @actions_connection.send_data next_action.to_s
              
              # If it's "causal event" action, we must wait here until it's fully responded
              next_action.response if next_action.has_causal_events?
            end
          rescue
            #
          end
          
          ##
          # When we send out an AMI action, we need to track the ActionID and have the other Thread handling the socket IO
          # notify the sending Thread that a response has been received. This method instantiates a new FutureResource and
          # keeps it around in a synchronized Hash for the IO-handling Thread to notify when a response with a matching
          # ActionID is seen again. See also data_for_message_received_with_action_id() which is how the IO-handling Thread
          # gets the metadata registered in the method back later.
          #
          # @param [ManagerInterfaceAction] action The ManagerInterfaceAction to send
          # @param [Hash] headers The other key/value pairs being sent with this message
          #
          def register_action_with_metadata(action)
            @sent_messages_lock.synchronize do
              @sent_messages[action.action_id] = action
            end
          end
          
          def data_for_message_received_with_action_id(action_id)
            @sent_messages_lock.synchronize do
              @sent_messages.delete action_id
            end
          end
          
          ##
          # Instantiates a new ManagerInterfaceActionsConnection and assigns it to @actions_connection.
          #
          # @return [EventSocket]
          #
          def establish_actions_connection
            @actions_connection = EventSocket.connect(@host, @port) do |handler|
              handler.receive_data { |data| @actions_lexer << data  }
              handler.connected    { actions_connection_established  }
              handler.disconnected { actions_connection_disconnected }
            end
            login @actions_connection, false
          end
          
          ##
          # Instantiates a new ManagerInterfaceEventsConnection and assigns it to @events_connection.
          #
          # @return [EventSocket]
          #
          def establish_events_connection
            # Note: the @events_connection instance variable is set in login()
            @events_connection = EventSocket.connect(@host, @port) do |handler|
              handler.receive_data { |data| @events_lexer << data  }
              handler.connected    { events_connection_established  }
              handler.disconnected { events_connection_disconnected }
            end
            login @events_connection, true
          end

          def login(connection, with_events)
            response = send_action_asynchronously_with_connection(connection, "Login",
                "Username" => @username, "Secret" => @password, "Events" => with_events ? "On" : "Off").response
            
            if response.kind_of? AMIError
              raise AuthenticationFailedException, "Incorrect username and password! #{response.message}"
            else
              response
            end
          rescue => exception
            # We must rescue all exceptions because EventMachine gives VERY cryptic error messages when an exception is
            # raised in post_init (which is what calls this method, usually).
            ahn_log.ami.error "Error logging in! #{exception.inspect}\n#{exception.backtrace.join("\n")}"
          end
          
          def parse_options(options)
            unrecognized_keys = options.keys.map { |key| key.to_sym } - DEFAULT_SETTINGS.keys
            if unrecognized_keys.any?
              raise ArgumentError, "Unrecognized named argument(s): #{unrecognized_keys.to_sentence}"
            end
            DEFAULT_SETTINGS.merge options
          end
          
          class AuthenticationFailedException < Exception; end
          
          class NotConnectedError < Exception; end
          
          ##
          # Each time ManagerInterface#send_action is invoked, a new ManagerInterfaceAction is invoked.
          #
          class ManagerInterfaceAction
            
            attr_reader :name, :headers, :future_resource, :action_id
            def initialize(name, headers={})
              @name, @headers = name.to_s.clone.freeze, headers.stringify_keys.clone.freeze
              @action_id = new_action_id.freeze
              @future_resource = FutureResource.new
            end
            
            def replies_with_action_id?
              ManagerInterface.replies_with_action_id?(@name, @headers)
            end
            
            def has_causal_events?
              ManagerInterface.has_causal_events?(@name, @headers)
            end
            
            ##
            # When sending an action with "causal events" (i.e. events which must be collected to form a proper
            # response), AMI should send a particular event which instructs us that no more events will be sent.
            # This event is called the "causal event terminator".
            #
            # @return [String] the lowercase()'d name of the event name for which to wait
            #
            def causal_event_terminator_name
              case @name.downcase
                when "queuestatus", 'parkedcalls'
                  @name.downcase + "complete"
              end
            end
            
            ##
            # Abstracts the generation of new ActionIDs. This could be implemented virutally any way, provided each invocation
            # returns something unique, so this will generate a GUID and return it.
            #
            def new_action_id
              new_guid # Implemented in lib/adhearsion/foundation/pseudo_guid.rb
            end
            
            def to_s
              @textual_representation ||= (
                  "Action: #{@name}\r\nActionID: #{@action_id}\r\n" +
                  @headers.map { |(key,value)| "#{key}: #{value}" }.join("\r\n") +
                  "\r\n\r\n"
              )
            end
            
            def response
              future_resource.resource
            end
            
          end
        end
      end
    end
  end
end
