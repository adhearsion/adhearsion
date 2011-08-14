# Hardcoding require for now since for some reason it's not being loaded
require 'adhearsion/voip/dsl/dialplan/control_passing_exception'

require 'adhearsion/version'
# JRuby contains a bug that breaks some of the menu functionality
# See: https://adhearsion.lighthouseapp.com/projects/5871/tickets/92-menu-method-under-jruby-does-not-appear-to-work
begin
  curver = Adhearsion::PkgVersion.new(JRUBY_VERSION)
  minver = Adhearsion::PkgVersion.new("1.6.0")
  if curver < minver
    puts "****************************************************************************"
    puts "Versions of JRuby prior to 1.6.0 contain a bug that impacts"
    puts "using the \"+\" operator to jump from one context to another."
    puts "Adhearsion has detected JRuby version #{JRUBY_VERSION}. For more information see:"
    puts "https://adhearsion.lighthouseapp.com/projects/5871/tickets/92-menu-method-under-jruby-does-not-appear-to-work"
    puts "****************************************************************************"
  end
rescue NameError
  # In case JRUBY_VERSION is not defined.
rescue ArgumentError
  # Needed to handle ActiveSupport's handling of missing constants
  # with anonymous modules under Ruby 1.9
end

module Adhearsion
  class DialPlan
    attr_accessor :loader, :entry_points
    def initialize(loader = Loader)
      @loader       = loader
      @entry_points = @loader.load_dialplans.contexts
    end

    ##
    # Lookup and return an entry point by context name
    #
    def lookup(context_name)
      entry_points[context_name]
    end

    ##
    # Executable environment for a dial plan in the scope of a call. This class has all the dialplan methods mixed into it.
    #
    class ExecutionEnvironment

      class << self
        def create(*args)
          new(*args).tap { |instance| instance.stage! }
        end
      end

      attr_reader :call
      def initialize(call, entry_point)
        @call, @entry_point = call, entry_point
      end

      ##
      # Adds the methods to this ExecutionEnvironment which make it useful. e.g. dialplan-related methods, call variables,
      # and component methods.
      #
      def stage!
        extend_with_voip_commands!
        extend_with_call_variables!
        extend_with_dialplan_component_methods!
      end

      def run
        raise "Cannot run ExecutionEnvironment without an entry point!" unless entry_point
        current_context = entry_point
        answer if AHN_CONFIG.automatically_answer_incoming_calls
        begin
          instance_eval(&current_context)
        rescue Adhearsion::VoIP::DSL::Dialplan::ControlPassingException => exception
          current_context = exception.target
          retry
        end
      end

      protected

      attr_reader :entry_point


      def extend_with_voip_commands!
        extend Adhearsion::VoIP::Conveniences
        extend Adhearsion::VoIP::Commands.for(call.originating_voip_platform)
      end

      def extend_with_call_variables!
        call.define_variable_accessors self
      end

      def extend_with_dialplan_component_methods!
        Components.component_manager.extend_object_with(self, :dialplan) if Components.component_manager
      end

      def ahn_log(*args)
        @call.ahn_log *args
      end

    end

    class Manager

      class NoContextError < StandardError; end

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
        if call.failed_call?
          environment = ExecutionEnvironment.create(call, nil)
          call.extract_failed_reason_from environment
          raise FailedExtensionCallException.new(environment)
        end

        if call.hungup_call?
          raise HungupExtensionCallException.new(ExecutionEnvironment.new(call, nil))
        end

        starting_entry_point = entry_point_for call
        raise NoContextError, "No dialplan entry point for call context '#{call.context}' -- Ignoring call!" unless starting_entry_point
        @context = ExecutionEnvironment.create(call, starting_entry_point)
        inject_context_names_into_environment @context
        @context.run
      end

      # Find the dialplan by the context name from the call or from the
      # first path entry in the AGI URL
      def entry_point_for(call)

        # Try the request URI for an entry point first
        if call.respond_to?(:request) && m = call.request.path.match(%r{/([^/]+)})
          if entry_point = dial_plan.lookup(m[1].to_sym)
            return entry_point
          else
            ahn_log.warn "AGI URI requested context \"#{m[1]}\" but matching Adhearsion context not found!  Falling back to Asterisk context."
          end
        end

        # Fall back to the matching Asterisk context name
        if entry_point = dial_plan.lookup(call.context.to_sym)
          return entry_point
        end
      end

      protected

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
          string_io = StringIO.new dial_plan_as_string
          def string_io.path
            "(eval)"
          end
          load_dialplans string_io
        end

        def load_dialplans(*files)
          files = Adhearsion::AHN_CONFIG.files_from_setting("paths", "dialplan") if files.empty?
          files = Array files
          files.map! do |file|
            case file
              when File, StringIO
                file
              when String
                File.new file
              else
                raise ArgumentError, "Unrecognized type of file #{file.inspect}"
            end
          end
          new.tap do |loader|
            files.each do |file|
              loader.load file
            end
          end
        end

      end

      self.default_dial_plan_file_name ||= 'dialplan.rb'

      def initialize
        @context_collector = ContextNameCollector.new
      end

      def contexts
        @context_collector.contexts
      end

      def load(dialplan_file)
        dialplan_code = dialplan_file.read
        @context_collector.instance_eval(dialplan_code, dialplan_file.path)
        nil
      end

      class ContextNameCollector# < ::BlankSlate

        class << self

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
          super if !block_given? || args.any?
          contexts[name] = DialplanContextProc.new(name, &block)
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
