require 'rubygems'
require 'pp'
require 'yaml'
require 'socket'
require 'thread'
require 'monitor'
require 'active_support'
require 'adhearsion/voip/asterisk/ami/parser'
require 'adhearsion/voip/asterisk/ami/commands'

module Adhearsion
  module VoIP
    module Asterisk
      class AMI
        include Commands
  
        attr_accessor :version

        def initialize(user, pass, host='127.0.0.1', hash={})
          @host, @user, @pass, @port = host, user, pass, hash[:port] || 5038
          @events = hash[:events]
        end
  
        def connect!
          disconnect!
          __start_event_thread if @events
          __login @host, @user, @pass, @port, false
        end
        
        def disconnect!
          @action_sock.close if @action_sock && !@action_sock.closed?
          @event_thread.kill if @event_thread
          @scanner.stop if @scanner
        end

        def [] cmd
          __cmd "command", @action_sock, :command => cmd
        end 

        def method_missing(name, hash={})
          __cmd name, @action_sock, hash
        end
  
        private
  
        def __login(host, user, pass, port, events)
          @action_sock = TCPSocket.new host, port
          @action_sock.extend(MonitorMixin)
          @scanner = Parser.new
          @version = @scanner.run(@action_sock)
          begin
            __cmd 'login', @action_sock, :username => user, :secret => pass, :events => (events ? "On" : "Off")
          rescue CommandError
            message = "Invalid AMI username/password! Check manager.conf."
            error message
            raise AuthenticationFailedException, message
          else
            # puts "Manager connection established to #{@host}:#{@port} with user '#{@user}'"
          end
        end
  
        def __cmd(name, sock, hash={})
          cmd = Command.build(name, hash)
          sock.synchronize do
            connect! if !sock || sock.closed?
            sock.write cmd.to_s
          end
          
          return nil if not cmd.has_response?
          @scanner.wait(cmd)
        end
        
        def __start_event_thread
          @event_thread = Thread.new(@scanner) do |scanner|
            loop { AMI::EventHandler.handle! __read_event(scanner.events.pop) rescue nil }
          end
        end
  
        class EventHandler
          @@subclasses = []

          def self.inherited(klass)
            @@subclasses << klass.new

            # Have to set this because singleton classes can't easily access
            # their owner's Class instance.
            klass.instance_variable_set :@me, klass
      
            def klass.method_added(name)
              if name == :initialize
                @@subclasses.each_with_index do |obj,i|
                  if obj.is_a? @me
                    @@subclasses[i] = @me.new
                    break
                  end
                end
              end
            end
          end

          def self.handle!(event)
            name = event.delete('Event').underscore
            @@subclasses.each do |klass|
              klass.send name, event if klass.respond_to? name
            end
          end
    
        end
  
        class AuthenticationFailedException < Exception; end
        class CommandError < RuntimeError; end
      end
    end
  end
end