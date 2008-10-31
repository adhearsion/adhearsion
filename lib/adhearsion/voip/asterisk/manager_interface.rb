require 'adhearsion/voip/asterisk/manager_interface/ami_parser'
require 'adhearsion/voip/asterisk/manager_interface/connections'

module Adhearsion
  module VoIP
    module Asterisk
      
      class AMI
        def initialize
          raise "Sorry, this AMI object has been deprecated. Please see http://docs.adhearsion.com/Asterisk_Manager_Interface for documentation on the new way of handling AMI. This new version is much better and should not require an enormous migration on your part."
        end
      end
      module Manager
        class ManagerInterface
          
          MANAGER_ACTIONS_WHICH_DONT_SEND_BACK_AN_ACTIONID = %w[
          
          ] unless defined? MANAGER_ACTIONS_WHICH_DONT_SEND_BACK_AN_ACTIONID
        
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
            :hostname => "localhost",
            :port     => 5038,
            :username => "admin",
            :password => "secret",
            :events   => true
          }.freeze unless defined? DEFAULT_SETTINGS
          
          attr_reader *DEFAULT_SETTINGS.keys
          
          ##
          # Creates a new Asterisk Manager Interface connection and exposes certain methods to control it.
          #
          # @param [Hash] options Available options are :hostname, :port, :username, :password, and :events
          #
          def initialize(options={})
            options = DEFAULT_SETTINGS.merge options
            @hostname = options[:host] || options[:hostname]
            @username = options[:user] || options[:username]
            @password = options[:pass] || options[:password]
            @events   = options[:events]
            @port     = options[:port]
            
            @sent_messages = {}
            @sent_messages_lock = Mutex.new
          end
        
          def action_message_received(message)
            if message.kind_of? Manager::Event
              Events.trigger %w[asterisk manager event], message
            elsif message.kind_of? Manager::ImmediateResponse
              # No ActionID! Release the write lock and wake up the waiter
            else
              action_id = message["ActionID"]
              data = data_for_message_received_with_action_id action_id
              
            end
          end
        
          def action_error_received(message)
            raise "GOT AN ERROR: #{message}"
          end
          
          def syntax_error_encountered(ignored_chunk)
            ahn_log.ami.error "ADHEARSION'S AMI PARSER ENCOUNTERED A SYNTAX ERROR! " + 
                "PLEASE REPORT THIS ON http://bugs.adhearsion.com! OFFENDING TEXT:\n#{ignored_chunk.inspect}"
          end

          def connect!
            establish_actions_connection
          end
        
          def disconnect!
            # TODO: Go through all the waiting condition variables and raise an exception
            raise NotImplementedError
          end
        
          def events_enabled?
            !! @events
          end
        
          def dynamic
            # TODO: Return an object which responds to method_missing
          end
        
          def post_init
            login!
          end
        
          ##
          # Used to directly send a new action to Asterisk. Note: NEVER supply an ActionID; these are handled internally.
          #
          # @param [String, Symbol] action_name The name of the action (e.g. Originate)
          #
          def send_action(action_name, headers={})
            headers = headers.stringify_keys
          
            if MANAGER_ACTIONS_WHICH_DONT_SEND_BACK_AN_ACTIONID.include? action_name.to_s.downcase
              raise NotImplementedError
            else
              action_id = headers["ActionID"] = new_action_id
          
              # TODO: Do some checking of the action name here and make sure it's something that's not totally fucked.
              command = "Action: #{action_name}\r\n"
              headers.each_pair { |key,value| command << "#{key}: #{value}\r\n" }
              command << "\r\n"
              
              condition_variable = register_sent_action_with_action_id(action_id, name, headers)
              
              @actions_connection.send_data command
              condition_variable.wait
            end
          
          end
        
          protected
          
          def register_sent_action_with_action_id(action_id, name, headers)
            condition_variable = ConditionVariable.new
            @sent_messages_lock.synchronize do
              @sent_messages[action_id] = {
                :name               => name,
                :headers            => headers,
                :action_id          => action_id,
                :condition_variable => condition_variable
              }
            end
            condition_variable
          end
          
          def data_for_message_received_with_action_id(action_id)
            @sent_messages_lock.synchronize do
              @sent_messages.delete action_id
            end
          end
          
          ##
          # Instantiates a new ManagerInterfaceActionsConnection and assigns it to @actions_connection.
          #
          # @return [EventMachine::Connection]
          def establish_actions_connection
            @actions_connection = EventMachine.connect @hostname, @port, ManagerInterfaceActionsConnection.new(self)
          end

          def new_action_id
            new_guid
          end
        
          def login
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
                
          class AuthenticationFailedException < Exception; end
          class ActionError < RuntimeError; end
        end
      end
    end
  end
end