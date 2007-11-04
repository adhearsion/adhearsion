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
  
  ##
  # Encapsulates call-related data and behavior.
  # For example, variables passed in on call initiation are
  # accessible here as attributes    
  class Call
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
    
    def define_variable_accessors(recipient=self)
      variables.each do |key, value| 
        recipient.class.send :attr_accessor, key unless recipient.class.respond_to?("#{key}=")
        recipient.send "#{key}=", value
      end
    end
    
    private
    
      def check_if_valid_call
        extension = variables['extension'] || variables[:extension]
        raise UselessCallException if extension == 't' || extension == 'failed' || extension == 'h'
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
