require 'uri'
#TODO Some of this is asterisk-specific
module Adhearsion
  class << self
    def active_calls
      @calls ||= Calls.new
    end
  
    def receive_call_from(io, &block)
      active_calls << (call = Call.receive_from(io, &block))
      call
    end
  end
  
  ##
  # This manages the list of calls the Adhearsion service receives
  class Calls
    def initialize
      @semaphore = Monitor.new
      @calls     = []
    end
    
    def <<(call)
      atomically do
        hangup_existing_calls_with_this_calls_id(call)
        calls << call
      end
    end
    
    def any?
      atomically do
        !calls.empty?
      end
    end
    
    def size
      atomically do
        calls.size
      end
    end
    
    def find(id)
      atomically do
        calls.detect {|call| call.uniqueid == id}
      end
    end
    
    def clear!
      calls.clear
    end
    
    private
      attr_reader :semaphore, :calls
      
      def atomically(&block)
        semaphore.synchronize(&block)
      end
        
      def hangup_existing_calls_with_this_calls_id(call)
        if existing_call = find(call.uniqueid)
          existing_call.hangup!
        end
      end
  end
  
  class UselessCallException < Exception; end
  
  class FailedExtensionCallException < Exception
    attr_reader :call
    def initialize(call)
      super()
      @call = call
    end
  end
  
  ##
  # Encapsulates call-related data and behavior.
  # For example, variables passed in on call initiation are
  # accessible here as attributes    
  class Call
    
    # This is basically a translation of ast_channel_reason2str() from main/channel.c and
    # ast_control_frame_type in include/asterisk/frame.h in the Asterisk source code. When
    # Asterisk jumps to the 'failed' extension, it sets a REASON channel variable to a number.
    # The indexes of these symbols represent the possible numbers REASON could be.
    ASTERISK_FRAME_STATES = [
      :failure,     # "Call Failure (not BUSY, and not NO_ANSWER, maybe Circuit busy or down?)"
      :hangup,      # Other end has hungup
      :ring,        # Local ring
      :ringing,     # Remote end is ringing
      :answer,      # Remote end has answered
      :busy,        # Remote end is busy
      :takeoffhook, # Make it go off hook
      :offhook,     # Line is off hook
      :congestion,  # Congestion (circuits busy)
      :flash,       # Flash hook
      :wink,        # Wink
      :option,      # Set a low-level option
      :radio_key,   # Key Radio
      :radio_unkey, # Un-Key Radio
      :progress,    # Indicate PROGRESS
      :proceeding,  # Indicate CALL PROCEEDING
      :hold,        # Indicate call is placed on hold
      :unhold,      # Indicate call is left from hold
      :vidupdate    # Indicate video frame update
    ]
    
    class << self
      ##
      # The primary public interface for creating a Call instance.
      # Given an IO (probably a socket accepted from an Asterisk service),
      # creates a Call instance which encapsulates everything we know about that call.
      def receive_from(io, &block)
        returning new(io, variable_parser_for(io).variables) do |call|
          block.call(call) if block
        end
      end
    
      private
      def variable_parser_for(io)
        Variables::Parser.parse(io)
      end
      
    end
    
    attr_accessor :io, :type, :variables, :originating_voip_platform
    def initialize(io, variables)
      @io, @variables = io, variables
      check_if_valid_call
      define_variable_accessors
      set_originating_voip_platform!
    end

    def hangup!
      io.close
    end

    def hung_up?
      io.closed?
    end
    
    # Asterisk sometimes uses the "failed" extension to indicate a failed dial attempt.
    # Since it may be important to handle these, this flag helps the dialplan Manager
    # figure that out.
    def failed_call?
      @failed_call
    end
    
    def define_variable_accessors(recipient=self)
      variables.each do |key, value| 
        define_singleton_accessor_with_pair(key, value, recipient)
      end
    end
    
    def extract_failed_reason_from(environment)
      if originating_voip_platform == :asterisk
        failed_reason = environment.variable 'REASON'
        failed_reason &&= ASTERISK_FRAME_STATES[failed_reason.to_i]
        define_singleton_accessor_with_pair(:failed_reason, failed_reason, environment)
      end
    end
    
    private
      
      def define_singleton_accessor_with_pair(key, value, recipient=self)
        recipient.class.send :attr_accessor, key unless recipient.class.respond_to?("#{key}=")
        recipient.send "#{key}=", value
      end
      
      def check_if_valid_call
        extension = variables['extension'] || variables[:extension]
        @failed_call = true if extension == 'failed'
        raise UselessCallException if extension == 't' || extension == 'h'
      end
    
      def set_originating_voip_platform!
        #TODO: we can make this determination programatically at some point,
        # but it will probably involve a bit more engineering than just a case statement (like
        # subclasses of Call for the various platforms), so we'll be totally cheap for now.
        self.originating_voip_platform = :asterisk
      end
    
    module Variables
      
      module Coercions

        COERCION_ORDER = %w{
          remove_agi_prefixes_from_keys_and_strip_whitespace
          coerce_keys_into_symbols
          coerce_extension_into_phone_number_object
          coerce_numerical_values_to_numerics
          replace_unknown_values_with_nil
          replace_yes_no_answers_with_booleans
          coerce_request_into_uri_object
          decompose_uri_query_into_hash
          remove_dashes_from_context_name
          coerce_type_of_number_into_symbol
        }

        class << self
          
          def remove_agi_prefixes_from_keys_and_strip_whitespace(variables)
            variables.inject({}) do |new_variables,(key,value)|
              returning new_variables do
                stripped_name = key.kind_of?(String) ? key[/^(agi_)?(.+)$/,2] : key
                new_variables[stripped_name] = key.kind_of?(String) ? value.strip : value
              end
            end
          end
          
          def coerce_keys_into_symbols(variables)
            variables.inject({}) do |new_variables,(key,value)|
              returning new_variables do
                new_variables[key.to_sym] = value
              end
            end
          end
          
          def coerce_extension_into_phone_number_object(variables)
            returning variables do
              variables[:extension] = Adhearsion::VoIP::DSL::PhoneNumber.new(variables[:extension])
            end
          end
          
          def coerce_numerical_values_to_numerics(variables)
            variables.inject({}) do |vars,(key,value)|
              returning vars do
                is_numeric = value =~ /^-?\d+(?:(\.)\d+)?$/
                is_float   = $1
                vars[key] = if is_numeric
                  if Adhearsion::VoIP::DSL::NumericalString.starts_with_leading_zero?(value)
                    Adhearsion::VoIP::DSL::NumericalString.new(value)
                  else
                    is_float ? value.to_f : value.to_i
                  end
                else
                  value
                end
              end
            end
          end

          def replace_unknown_values_with_nil(variables)
            variables.each do |key,value|
              variables[key] = nil if value == 'unknown'
            end
          end

          def replace_yes_no_answers_with_booleans(variables)
            variables.each do |key,value|
              case value
                when 'yes' : variables[key] = true
                when 'no'  : variables[key] = false
              end
            end
          end
          
          def coerce_request_into_uri_object(variables)
            returning variables do
              variables[:request] = URI.parse(variables[:request]) unless variables[:request].kind_of? URI
            end
          end

          def coerce_type_of_number_into_symbol(variables)
            returning variables do
              variables[:type_of_calling_number] = Adhearsion::VoIP::Constants::Q931_TYPE_OF_NUMBER[variables.delete(:callington).to_i]
            end
          end
          
          def decompose_uri_query_into_hash(variables)
            returning variables do
              if variables[:request].query
                variables[:query] = variables[:request].query.split('&').inject({}) do |query_string_parameters, key_value_pair|
                  parameter_name, parameter_value = *key_value_pair.match(/(.+)=(.+)/).captures
                  query_string_parameters[parameter_name] = parameter_value
                  query_string_parameters
                end
              else
                variables[:query] = {}
              end
            end
          end

          def remove_dashes_from_context_name(variables)
            returning variables do
              variables[:context].gsub!('-', '_')
            end
          end
          
        end
      end

      class Parser
        
        class << self
          def parse(*args, &block)
            returning new(*args, &block) do |parser|
              parser.parse
            end
          end
          
          def coerce_variables(variables)
            Coercions::COERCION_ORDER.inject(variables) do |tmp_variables, coercing_method_name|
              Coercions.send(coercing_method_name, tmp_variables)
            end
          end
          
          def separate_line_into_key_value_pair(line)
            line.match(/^([^:]+):\s?(\S*)/).captures
          end
        end
      
        attr_reader :io, :variables, :lines
        def initialize(io)
          @io = io
          @lines = []
        end
      
        def parse
          extract_variable_lines_from_io
          initialize_variables_as_hash_from_lines
          @variables = self.class.coerce_variables(variables)
        end
        
        private
          
          def initialize_variables_as_hash_from_lines
            @variables = lines.inject({}) do |new_variables,line|
              returning new_variables do
                key, value = self.class.separate_line_into_key_value_pair line
                new_variables[key] = value
              end
            end
          end
          
          def extract_variable_lines_from_io
            while line = io.readline.chomp
              break if line.empty?
              @lines << line
            end
          end
        
      end
    
    end
  end  
end
