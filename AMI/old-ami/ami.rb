require 'rubygems'
require 'pp'
require 'yaml'
require 'socket'
require 'thread'
require 'monitor'
require 'adhearsion/voip/asterisk/manager_interface/ami_lexer'

module Adhearsion
  module VoIP
    module Asterisk
      class AMI
        
        attr_reader :action_sock, :host, :user, :password, :port, :event_thread, :scanner, :version

        ##
        # Creates a new Asterisk Manager Interface connection and exposes certain methods to control it.
        #
        # @param [Hash] options 
        #
        def initialize(*options)
          if options.size == 1 && options.first.kind_of?(Hash)
            options = options.first
          else
            options = check_deprecation options
          end
          
          
          @host, @user, @password, @port = options.values_athost, user, pass, options[:port] || 5038
          @events_enabled = options[:events]
          create
        end
        
        include Adhearsion::Publishable
        
        publish :through => :proxy do
          
          def originate(options={})
            options[:callerid] = options.delete :caller_id if options[:caller_id]
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
            args[:priority]  = options[:priority] || 1
            args[:extension] = options[:extension] if options[:extension]
            args[:caller_id] = options[:caller_id] if options[:caller_id]
            args[:timeout]   = options[:timeout]   if options[:timeout]
            if options[:variables] && options[:variables].kind_of?(Hash)
              args[:variable] = options[:variables].map {|pair| pair.join('=')}.join('|')
            end
            originate args
          end

          def method_missing(name, hash={}, &block)
            execute_ami_command! name, hash, &block
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
        
        private
  
        def check_deprecation(options)
          # old initialize: user, pass, host='127.0.0.1', options={}
          if (2..4).include? options.size
            {}
          else
            raise ArgumentError
          end
        end
  
        def login!(host, user, pass, port, events)
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
        
        def execute_ami_command!
          ahn_log.ami.error "Sorry, this method has been deprecated."
        end
        
        def execute_ami_command!(name, options={}, &block)
          action_sock.synchronize do
            connect! if !action_sock || action_sock.closed?
            action_sock.write action.to_s
          end
          
          return unless action.has_response?
        end
        
        class AuthenticationFailedException < Exception; end
        class ActionError < RuntimeError; end
      end
    end
  end
end
