require File.join(File.dirname(__FILE__), 'ami_messages.rb')

module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class AbstractAsteriskManagerInterfaceStreamLexer

          BUFFER_SIZE = 128.kilobytes unless defined? BUFFER_SIZE

          ##
          # IMPORTANT! See method documentation for adjust_pointers!
          #
          # @see  adjust_pointers
          #
          POINTERS = [
            :@current_pointer,
            :@token_start,
            :@token_end,
            :@version_start,
            :@event_name_start,
            :@current_key_position,
            :@current_value_position,
            :@last_seen_value_end,
            :@error_reason_start,
            :@follows_text_start,
            :@current_syntax_error_start,
            :@immediate_response_start
            ]

          %%{
          	machine ami_protocol_parser;

            # All required Ragel actions are implemented as Ruby methods.

            # Executed after a "Response: Success" or "Response: Pong"
            action init_success { init_success }

            action init_response_follows { init_response_follows }

            action init_error { init_error }

            action message_received { message_received @current_message }
            action error_received   {   error_received @current_message }

            action version_starts { version_starts }
            action version_stops  { version_stops  }

            action key_starts { key_starts }
            action key_stops  { key_stops  }

            action value_starts { value_starts }
            action value_stops  { value_stops  }

            action error_reason_starts { error_reason_starts }
            action error_reason_stops  { error_reason_stops  }

            action syntax_error_starts { syntax_error_starts }
            action syntax_error_stops  { syntax_error_stops  }

            action immediate_response_starts { immediate_response_starts }
            action immediate_response_stops  { immediate_response_stops  }

            action follows_text_starts { follows_text_starts }
            action follows_text_stops  { follows_text_stops  }

            action event_name_starts { event_name_starts }
            action event_name_stops  { event_name_stops  }

            include ami_protocol_parser_machine "ami_protocol_lexer_machine.rl";

          }%%##

          attr_accessor(:ami_version)
          def initialize

            @data = ""
            @current_pointer = 0
            @ragel_stack = []
            @ami_version = 0.0

            %%{
              # All other variables become local, letting Ruby garbage collect them. This
              # prevents us from having to manually reset them.

        			variable data  @data;
              variable p     @current_pointer;
        			variable pe    @data_ending_pointer;
        			variable cs    @current_state;
        			variable ts    @token_start;
        			variable te    @token_end;
        			variable act   @ragel_act;
        			variable eof   @eof;
			        variable stack @ragel_stack;
			        variable top   @ragel_stack_top;

        			write data;
              write init;
            }%%##

          end

          def <<(new_data)
            extend_buffer_with new_data
            resume!
          end

          def resume!
            %%{ write exec; }%%##
          end

          def extend_buffer_with(new_data)
            length = new_data.size

            if length > BUFFER_SIZE
              raise Exception, "ERROR: Buffer overrun! Input size (#{new_data.size}) larger than buffer (#{BUFFER_SIZE})"
            end

            if length + @data.size > BUFFER_SIZE
              if @data.size != @current_pointer
                if @current_pointer < length
                  # We are about to shift more bytes off the array than we have
                  # parsed.  This will cause the parser to lose state so
                  # integrity cannot be guaranteed.
                  raise Exception, "ERROR: Buffer overrun! AMI parser cannot guarantee sanity. New data size: #{new_data.size}; Current pointer at #{@current_pointer}; Data size: #{@data.size}"
                end
              end
              @data.slice! 0...length
              adjust_pointers -length
            end
            @data << new_data
            @data_ending_pointer = @data.size
          end

          protected

          ##
          # This method will adjust all pointers into the buffer according
          # to the supplied offset.  This is necessary any time the buffer
          # changes, for example when the sliding window is incremented forward
          # after new data is received.
          #
          # It is VERY IMPORTANT that when any additional pointers are defined
          # that they are added to this method.  Unpredictable results may
          # otherwise occur!
          #
          # @see https://adhearsion.lighthouseapp.com/projects/5871-adhearsion/tickets/72-ami-lexer-buffer-offset#ticket-72-26
          #
          # @param offset Adjust pointers by offset.  May be negative.
          #
          def adjust_pointers(offset)
            POINTERS.each do |ptr|
              value = instance_variable_get(ptr)
              instance_variable_set(ptr, value + offset) if !value.nil?
            end
          end

          ##
          # Called after a response or event has been successfully parsed.
          #
          # @param [ManagerInterfaceResponse, ManagerInterfaceEvent] message The message just received
          #
          def message_received(message)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          ##
          # Called when there is an Error: stanza on the socket. Could be caused by executing an unrecognized command, trying
          # to originate into an invalid priority, etc. Note: many errors' responses are actually tightly coupled to a
          # ManagerInterfaceEvent which comes directly after it. Often the message will say something like "Channel status
          # will follow".
          #
          # @param [String] reason The reason given in the Message: header for the error stanza.
          #
          def error_received(reason)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          ##
          # Called when there's a syntax error on the socket. This doesn't happen as often as it should because, in many cases,
          # it's impossible to distinguish between a syntax error and an immediate packet.
          #
          # @param [String] ignored_chunk The offending text which caused the syntax error.
          def syntax_error_encountered(ignored_chunk)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          def init_success
            @current_message = ManagerInterfaceResponse.new
          end

          def init_response_follows
            @current_message = ManagerInterfaceResponse.new
          end

          def init_error
            @current_message = ManagerInterfaceError.new()
          end

          def version_starts
            @version_start = @current_pointer
          end

          def version_stops
            self.ami_version = @data[@version_start...@current_pointer].to_f
            @version_start = nil
          end

          def event_name_starts
            @event_name_start = @current_pointer
          end

          def event_name_stops
            event_name = @data[@event_name_start...@current_pointer]
            @event_name_start = nil
            @current_message = ManagerInterfaceEvent.new(event_name)
          end

          def key_starts
            @current_key_position = @current_pointer
          end

          def key_stops
            @current_key = @data[@current_key_position...@current_pointer]
          end

          def value_starts
            @current_value_position = @current_pointer
          end

          def value_stops
            @current_value = @data[@current_value_position...@current_pointer]
            @last_seen_value_end = @current_pointer + 2 # 2 for \r\n
            add_pair_to_current_message
          end

          def error_reason_starts
            @error_reason_start = @current_pointer
          end

          def error_reason_stops
            @current_message.message = @data[@error_reason_start...@current_pointer]
          end

          def follows_text_starts
            @follows_text_start = @current_pointer
          end

          def follows_text_stops
            text = @data[@last_seen_value_end..@current_pointer]
            text.sub! /\r?\n--END COMMAND--/, ""
            @current_message.text_body = text
            @follows_text_start = nil
          end

          def add_pair_to_current_message
            @current_message[@current_key] = @current_value
            reset_key_and_value_positions
          end

          def reset_key_and_value_positions
            @current_key, @current_value, @current_key_position, @current_value_position = nil
          end

          def syntax_error_starts
            @current_syntax_error_start = @current_pointer # Adding 1 since the pointer is still set to the last successful match
          end

          def syntax_error_stops
            # Subtracting 3 from @current_pointer below for "\r\n" which separates a stanza
            offending_data = @data[@current_syntax_error_start...@current_pointer - 1]
            syntax_error_encountered offending_data
            @current_syntax_error_start = nil
          end

          def immediate_response_starts
            @immediate_response_start = @current_pointer
          end

          def immediate_response_stops
            message = @data[@immediate_response_start...(@current_pointer -1)]
            message_received ManagerInterfaceResponse.from_immediate_response(message)
          end

          ##
          # This method is used primarily in debugging.
          #
          def view_buffer(message=nil)

            message ||= "Viewing the buffer"

            buffer = @data.clone
            buffer.insert(@current_pointer, "\033[0;31m\033[1;31m^\033[0m")

            buffer.gsub!("\r", "\\\\r")
            buffer.gsub!("\n", "\\n\n")

            puts <<-INSPECTION
VVVVVVVVVVVVVVVVVVVVVVVVVVVVV
####  #{message}
#############################
#{buffer}
#############################
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            INSPECTION

          end
        end
        class DelegatingAsteriskManagerInterfaceLexer < AbstractAsteriskManagerInterfaceStreamLexer

          def initialize(delegate, method_delegation_map=nil)
            super()
            @delegate = delegate

            @message_received_method = method_delegation_map && method_delegation_map.has_key?(:message_received) ?
                method_delegation_map[:message_received] : :message_received

            @error_received_method = method_delegation_map && method_delegation_map.has_key?(:error_received) ?
                method_delegation_map[:error_received] : :error_received

            @syntax_error_method = method_delegation_map && method_delegation_map.has_key?(:syntax_error_encountered) ?
                method_delegation_map[:syntax_error_encountered] : :syntax_error_encountered
          end

          def message_received(message)
            @delegate.send(@message_received_method, message)
          end

          def error_received(message)
            @delegate.send(@error_received_method, message)
          end

          def syntax_error_encountered(ignored_chunk)
            @delegate.send(@syntax_error_method, ignored_chunk)
          end

        end
      end
    end
  end
end
