module Adhearsion
  
  # This module, albeit initially empty, contains the
  # execution of the helpers. To access the helpers,
  # use Adhearsion::Helpers.module_eval() or include it
  # in your working namespace.
  module Helpers
    # TODO: Maybe allow some kind of documentation for the
    # methods (a-la Rake) using method_added and describe?
  end
  
  module HelperSupport
    module HelperLoader
      
      def self.load!
        return unless Adhearsion::Paths.manager_for? "helpers"
        Adhearsion::Hooks::BeforeHelpersLoad.trigger_hooks
        
        HelperLoader.constants.grep(/.+HelperLoader$/).map do |mod|
          HelperLoader.const_get mod
        end.each &:load!
        
        Adhearsion::Hooks::AfterHelpersLoad.trigger_hooks
      end
      
      module RubyHelperLoader
        
        def self.load!
          my_helpers.each do |helper|
            code = File.read helper
            begin
              Helpers.module_eval code, helper
            rescue => exception
              fixed_backtrace = exception.backtrace.map do |e|
                e.sub "(eval)", helper
              end
              exception.set_backtrace fixed_backtrace
              raise exception
            end
          end
        end
        
        def self.my_helpers
          all_helpers.grep /\.rb$/
        end
      end
    end
  end
end