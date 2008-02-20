# Hardcoding require for now since for some reason it's not being loaded
require 'adhearsion/blank_slate'
require 'adhearsion/component_manager'
require 'adhearsion/voip/dsl/dialplan/control_passing_exception'

module Adhearsion
  class DialPlan
    attr_accessor :loader, :entry_points
    def initialize(loader = Loader)
      @loader       = loader
      @entry_points = @loader.load_dial_plan.contexts
    end
    
    ##
    # Lookup and return an entry point by context name
    def lookup(context_name)
      entry_points[context_name]
    end
    
    ##
    # Executable environment for a dial plan in the scope of a call
    class ExecutionEnvironment
      
      attr_reader :call
      def initialize(call, entry_point)
        @call, @entry_point = call, entry_point
        extend_with_voip_commands!
        extend_with_call_variables!
        extend_with_components_with_call_context!
      end
      
      def run
        current_context = entry_point
        begin
          instance_eval(&current_context)
        rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException => exception
          current_context = exception.target
          retry
        end
      end
      
      private
        attr_reader :entry_point
        
        def extend_with_voip_commands!
          extend(Adhearsion::VoIP::Commands.for(call.originating_voip_platform))
        end
        
        def extend_with_call_variables!
          call.define_variable_accessors self
        end
        
        def extend_with_components_with_call_context!
          ComponentManager.components_with_call_context.keys.each do |component_name|
            eval <<-COMPONENT_BUILDER
              def self.new_#{component_name.underscore}(*args, &block)
                ComponentManager.components_with_call_context['#{component_name}'].instantiate_with_call_context(self, *args, &block)
              end
            COMPONENT_BUILDER
          end
        end
    end
    
    class Manager
      
      class NoContextError < Exception; end
      
      class << self
        def handle(call)
          new.handle(call)
        end
      end
      
      attr_accessor :dial_plan, :context
      def initialize
        @dial_plan = DialPlan.new
      end
      
      def handle(call)
        starting_entry_point = entry_point_for call
        raise NoContextError, "No dialplan entry point for call context '#{call.context}' -- Ignoring call!" unless starting_entry_point
        
        @context = ExecutionEnvironment.new(call, starting_entry_point)
        inject_context_names_into_environment(@context)
        ahn_log "Entering context #{starting_entry_point}"
        @context.run
      end
      
      def entry_point_for(call)
        dial_plan.lookup(call.context.to_sym)
      end
      
      private
      
      def inject_context_names_into_environment(environment)
        return unless dial_plan.entry_points
        dial_plan.entry_points.each do |name, context|
          environment.meta_def(name) { context }
        end
      end
      
    end
    
    class Loader
      class << self
        attr_accessor :default_dial_plan_file_name
        
        def load(dial_plan_as_string)
          returning new do |loader|
            inject_dial_plan_component_classes_into dial_plan_as_string
            loader.load(dial_plan_as_string)
          end
        end
        
        def load_dial_plan(file_name = default_dial_plan_file_name)
          load read_dialplan_file(AHN_ROOT.dial_plan_named(file_name))
        end
        
        private
          def inject_dial_plan_component_classes_into(dial_plan_as_string)
            dial_plan_as_string[0, 0] = ComponentManager.components_with_call_context.keys.map do |component| 
              "#{component} = ::Adhearsion::ComponentManager.components_with_call_context['#{component}']\n"
            end.join
          end
          
          def read_dialplan_file(filename)
            File.read filename
          end
          
      end
      
      self.default_dial_plan_file_name ||= 'dialplan.rb'

      attr_reader :contexts
      def initialize
        @contexts = {}
      end
      
      def load(dial_plan_as_string)
        contexts.update(Builder.build(dial_plan_as_string))
      end
      
      class Builder < ::BlankSlate
        
        class << self
          def build(dial_plan_as_string)
            builder = new
            builder.instance_eval(dial_plan_as_string)
            builder.contexts
          end
          def const_missing(name)
            super
          rescue ArgumentError
            raise NameError, %(undefined constant "#{name}")
          end
        end
        
        attr_reader :contexts
        def initialize
          @contexts = {}
        end
        
        def method_missing(name, *args, &block)
          super unless block_given?
          contexts[name] = DialplanContextProc.new name, &block
        end
      end
    end
    class DialplanContextProc < Proc
      
      attr_reader :name
      
      def initialize(name, &block)
        super(&block)
        @name = name
      end
      
      def +@
        raise Adhearsion::VoIP::DSL::Dialplan::ControlPassingException.new(self)
      end
      
    end
  end
end
