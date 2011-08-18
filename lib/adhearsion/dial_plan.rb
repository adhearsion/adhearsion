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
    extend ActiveSupport::Autoload

    autoload :ConfirmationManager
    autoload :ExecutionEnvironment
    autoload :Loader
    autoload :Manager

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

    class DialplanContextProc < Proc

      attr_reader :name

      def initialize(name, &block)
        super(&block)
        @name = name
      end

      def +@
        raise Adhearsion::DSL::Dialplan::ControlPassingException.new(self)
      end

    end
  end
end
