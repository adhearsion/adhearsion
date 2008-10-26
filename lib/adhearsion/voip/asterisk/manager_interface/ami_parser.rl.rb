require File.join(File.dirname(__FILE__), 'packets.rb')

module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class AbstractAsteriskManagerInterfaceStreamParser

          BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

          CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
          CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS
          
          %%{
          	machine ami_protocol_parser;
          
            # Executed after a "Respone: Success" or "Response: Pong"
            action init_success { init_success }
          
            action init_response_follows { init_response_follows }
          
            action message_received { message_received @current_message }
          
            action version_starts { version_starts }
            action version_stops  { version_stops  }
          
            action key_starts { key_starts }
            action key_stops  { key_stops  }
          
            action value_starts { value_starts }
            action value_stops  { value_stops  }
          
            action error_reason_starts { error_reason_starts }
            action error_reason_stops  { error_reason_stops }
          
            action syntax_error_starts { syntax_error_starts }
            action syntax_error_stops  { syntax_error_stops  }
          
            action immediate_response_starts { immediate_response_starts }
            action immediate_response_stops  { immediate_response_stops  }
          
            action follows_text_starts { follows_text_starts }
            action follows_text_stops  { follows_text_stops  }
          
            action event_name_starts { event_name_starts }
            action event_name_stops  { event_name_stops  }
          
            include ami_protocol_parser_machine "ami_protocol_parser_machine.rl";
    
          }%%##

          attr_accessor(:ami_version)
          def initialize
    
            @data = ""
            @current_pointer = 0
            @ragel_stack = []
            
            %%{
              # All other variables become local, letting Ruby garbage collect them. This
              # prevents us from having to manually reset them.
      
        			variable data @data;
              variable p @current_pointer;
        			variable pe @data_ending_pointer;
        			variable cs @current_state;
        			variable ts @token_start;
        			variable te @token_end;
        			variable stack @stack;
        			variable act @ragel_act;
        			variable eof @eof;
			        variable stack @ragel_stack;
			        variable top @ragel_stack_top;
			        
        			write data nofinal;
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
            if new_data.size + @data.size > BUFFER_SIZE
              @data.slice! 0...new_data.size
              @current_pointer = @data.size
            end
            @data << new_data
            @data_ending_pointer = @data.size
          end
        
          protected
                
          ##
          # Called after a response or event has been successfully parsed.
          #
          # @param [NormalAmiResponse, ImmediateResponse, Event] message The message just received
          #
          def message_received(message)
            raise NotImplementedError, "Must be implemented in subclass!"
          end

          ##
          # Called when there is an Error: stanza on the socket. Could be caused by executing an unrecognized command, trying
          # to originate into an invalid priority, etc. Note: many errors' responses are actually tightly coupled to an Event
          # which comes directly after it. Often the message will say something like "Channel status will follow".
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
            @current_message = NormalAmiResponse.new
          end
        
          def init_response_follows
            @current_message = NormalAmiResponse.new(true)
          end
  
          def version_starts
            @start_of_version = @current_pointer
          end
  
          def version_stops
            self.ami_version = @data[@start_of_version...@current_pointer].to_f
            @start_of_version = nil
          end
  
          def begin_capturing_variable(variable_name)
            @start_of_current_capture = @current_pointer
          end
  
          def finish_capturing_variable(variable_name)
            start, stop = @start_of_current_capture, @current_pointer
            return :failed if !start || start > stop
            capture = @data[start...stop]
            CAPTURED_VARIABLES[variable_name] = capture
            capture
          end
  
          def event_name_starts
            @event_name_start = @current_pointer
          end
  
          def event_name_stops
            event_name = @data[@event_name_start...@current_pointer]
            @event_name_start = nil
            @current_message = Event.new(event_name)
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
            error_received @data[@error_reason_start...@current_pointer - 3]
            @error_reason_start = nil
          end
  
          def follows_text_starts
            @follows_text_start = @current_pointer
          end
  
          def follows_text_stops
            text = @data[@last_seen_value_end..(@current_pointer - "\r\n--END COMMAND--".size)]
            @current_message.text = text
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
            message_received ImmediateResponse.new(message)
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
      end
    end
  end
end