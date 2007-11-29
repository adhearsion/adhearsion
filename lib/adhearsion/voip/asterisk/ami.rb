require 'rubygems'
require 'pp'
require 'yaml'
require 'socket'
require 'thread'
require 'monitor'
require 'active_support'
require 'adhearsion/voip/asterisk/ami/parser'
require 'adhearsion/voip/asterisk/ami/actions'

module Adhearsion
  module VoIP
    module Asterisk
      class AMI
        
        include Actions
        
        attr_reader :action_sock, :host, :user, :password, :port, :event_thread, :scanner, :version

        def initialize(user, pass, host='127.0.0.1', options={})
          @host, @user, @password, @port = host, user, pass, options[:port] || 5038
          @events_enabled = options[:events]
        end
        
        include Adhearsion::Publishable
        
        publish :through => :proxy do
          
          def originate(options={}, &block)
            execute_ami_command! :originate, action_sock, options, &block
          end

          def ping
            execute_ami_command! :ping, action_sock
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
        
        def method_missing(name, hash={}, &block)
          execute_ami_command! name, action_sock, hash, &block
        end
  
        private
  
        def login!(host, user, pass, port, events)
          begin
            @action_sock = TCPSocket.new host, port
          rescue Errno::ECONNREFUSED => refusal_error
            raise Errno::ECONNREFUSED, "Could not connect with AMI to Asterisk server at #{host}:#{port}. " +
                                       "Is enabled set to 'yes' in manager.conf?"
          end
          action_sock.extend(MonitorMixin)
          @scanner = Parser.new
          @version = scanner.run(action_sock)
          begin
            execute_ami_command! :login, action_sock, :username => user, :secret => password, :events => (events_enabled? ? "On" : "Off")
          rescue ActionError
            raise AuthenticationFailedException, "Invalid AMI username/password! Check manager.conf."
          else
            # puts "Manager connection established to #{host}:#{port} with user '#{user}'"
          end
        end
  
        def execute_ami_command!(name, sock, hash={}, &block)
          action = Action.build(name, hash, &block)
          sock.synchronize do
            connect! if !sock || sock.closed?
            sock.write action.to_s
          end
          
          return unless action.has_response?
          scanner.wait(action)
        end
        
        def start_event_thread!
          @event_thread = Thread.new(scanner) do |scanner|
            loop do
              # TODO: This is totally screwed up. __read_event doesn't exist.
              AMI::EventHandler.handle! __read_event(scanner.events.pop)
            end
          end
          event_thread.abort_on_exception = true
        end
  
        # Method simply defined as private to prevent method_missing from catching it.
        def events() end
  
        class EventHandler
          # TODO: Refactor me!
        end
  
        class AuthenticationFailedException < Exception; end
        class ActionError < RuntimeError; end
      end
    end
  end
end