require 'rubygems'
require 'active_support'

require File.join(File.dirname(__FILE__), 'packets.rb')

class AmiStreamParser

  BUFFER_SIZE = 8.kilobytes

  CAPTURED_VARIABLES   = {}
  CAPTURE_CALLBACKS    = {}

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
    
    action before_action_id { before_action_id }
    action after_action_id  { after_action_id  }

    action message_received { message_received @current_message }

    action start_ignoring_syntax_error {
      fhold;
      start_ignoring_syntax_error;
      fgoto error_recovery;
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
      fgoto main;
    }
    
    action begin_capturing_event_name { begin_capturing_event_name }
    action init_event { init_event }
    
    action init_response_follows {
      @current_message = NormalAmiResponse.new(true)
      fgoto response_follows;
    }
    
    include ami_protocol_parser_common "common.rl";
    
  }%% # %

  attr_reader :ami_version
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
    p [:starting, {:current_pointer => @current_pointer, :data => @data, :ending => @data_ending_pointer}]
    if new_data.size + @data.size > BUFFER_SIZE
      @data.slice! 0...new_data.size
      @current_pointer = @data.size
    end
    @data << new_data
    @data_ending_pointer = @data.size
    resume!
    p [:ending, {:current_pointer => @current_pointer, :data => @data, :ending => @data_ending_pointer, :message => @current_message}]
  end
  
  protected
  
  def resume!
    %%{ write exec; }%%
  end
  
  def open_version
    @start_of_version = @current_pointer
  end
  
  def close_version
    @ami_version = @data[@start_of_version...@current_pointer].to_f
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
    CAPTURE_CALLBACKS[variable_name].call(capture) if CAPTURE_CALLBACKS.has_key? variable_name
    capture
  end
  
  def begin_capturing_event_name
    @event_name_start = @current_pointer
  end
  
  def init_event
    event_name = @data[@event_name_start]
    @event_name_start = nil
    @current_message = Event.new(event_name)
    puts "Instantiated new event"
  end
  
  # This method must do someting with @current_message or it'll be lost.
  def message_received(current_message)
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
    add_pair_to_current_message
  end
  
  def before_action_id
    @start_action_id = @current_pointer
  end
  
  def after_action_id
    @current_message.action_id = @data[@start_action_id...@current_pointer]
    puts "ActionID: #{current_message.action_id}"
    @start_action_id = nil
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
    text = @data[@follows_text_start..(@current_pointer - "\r\n--END COMMAND--".size)]
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
    @current_syntax_error_start = @current_pointer + 1 # Adding 1 since the pointer is still set to the last successful match
  end
  
  def end_ignoring_syntax_error
    syntax_error! @data[@current_syntax_error_start...@current_pointer - 3] # Subtracting 3 for "\r\n\r" which separates a stanza
    @current_syntax_error_start = nil
  end
  
  def capture_callback_for(variable_name, &block)
    CAPTURE_CALLBACKS[variable_name] = block
  end
  
  def ami_error!(reason)
    puts "errroz! #{reason}"
    # raise "AMI Error: #{reason}"
  end
  
  def syntax_error!(ignored_chunk)
    p "Ignoring this: #{ignored_chunk}"
  end
  
end
