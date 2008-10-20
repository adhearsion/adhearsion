# -*- ruby -*-
require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  BUFFER_SIZE = 8.kilobytes unless defined? BUFFER_SIZE

  CAPTURED_VARIABLES = {} unless defined? CAPTURED_VARIABLES
  CAPTURE_CALLBACKS  = {} unless defined? CAPTURE_CALLBACKS

  %%{ #%#
  	machine ami_protocol_parser;
    
    action before_prompt { before_prompt }
    action after_prompt  { after_prompt  }
    action open_version  { open_version }
    action close_version { close_version }
    
    action before_key    { begin_capturing_key  }
    action after_key     { finish_capturing_key }
    
    action before_value  { begin_capturing_value  }
    action after_value   { finish_capturing_value }
    
    action error_reason_start { error_reason_start }
    action error_reason_end   { error_reason_end; fgoto main; }
    
    action message_received { message_received @current_message }

    action start_ignoring_syntax_error {
      start_ignoring_syntax_error;
    }
    action end_ignoring_syntax_error {
      end_ignoring_syntax_error;
      fgoto main;
    }
    
    # Executed after a "Respone: Success" or a Pong
    action init_success {
      @current_message = NormalAmiResponse.new
    }
    
    action start_capturing_follows_text { start_capturing_follows_text }
    action end_capturing_follows_text   {
      end_capturing_follows_text;
    }
    
    action begin_capturing_event_name { begin_capturing_event_name }
    action init_event { init_event }
    
    action init_response_follows {
      @current_message = NormalAmiResponse.new(true)
      fgoto response_follows;
    }
    
    include ami_protocol_parser_common "common.rl";
    
  }%% # %

  attr_accessor :ami_version
  def initialize
    
    @data = ""
    @current_pointer = 0
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
			
			write data nofinal;
      write init;
    }%%
  end
  
  def <<(new_data)
    if new_data.size + @data.size > BUFFER_SIZE
      @data.slice! 0...new_data.size
      @current_pointer = @data.size
    end
    @data << new_data
    @data_ending_pointer = @data.size
    resume!
  end
  
  def resume!
    %%{ write exec; }%%
  end
  
  protected
  
  def open_version
    @start_of_version = @current_pointer
  end
  
  def close_version
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
  
  def begin_capturing_event_name
    @event_name_start = @current_pointer
  end
  
  def init_event
    event_name = @data[@event_name_start]
    @event_name_start = nil
    @current_message = Event.new(event_name)
  end
  
  # TODO: Add it to events system.
  def message_received(current_message=@current_message)
    current_message
  end
  
  def begin_capturing_key
    @current_key_position = @current_pointer
  end
  
  def finish_capturing_key
    @current_key = @data[@current_key_position...@current_pointer]
  end
  
  def begin_capturing_value
    @current_value_position = @current_pointer
  end
  
  def finish_capturing_value
    @current_value = @data[@current_value_position...@current_pointer]
    @last_seen_value_end = @current_pointer + 2 # 2 for \r\n
    add_pair_to_current_message
  end
  
  def error_reason_start
    @error_reason_start = @current_pointer
  end
  
  def error_reason_end
    ami_error! @data[@error_reason_start...@current_pointer]
    @error_reason_start = nil
  end
  
  def start_capturing_follows_text
    @follows_text_start = @current_pointer
  end
  
  def end_capturing_follows_text
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
  
  def start_ignoring_syntax_error
    @current_syntax_error_start = @current_pointer # Adding 1 since the pointer is still set to the last successful match
  end
  
  def end_ignoring_syntax_error
    # Subtracting 3 from @current_pointer below for "\r\n\r" which separates a stanza
    offending_data = @data[@current_syntax_error_start...@current_pointer - 3]
    syntax_error! offending_data
    @current_syntax_error_start = nil
  end
  
  # TODO: Invoke Theatre
  def ami_error!(reason)
    # raise "AMI Error: #{reason}"
  end
  
  # TODO: Invoke Theatre
  def syntax_error!(ignored_chunk)
    p "Ignoring this: #{ignored_chunk}"
  end
  
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