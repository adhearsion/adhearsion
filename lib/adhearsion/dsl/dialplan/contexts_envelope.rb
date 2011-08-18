module Adhearsion
  module DSL
    class Dialplan
      class ContextsEnvelope
        keep = [:define_method, :instance_eval, :meta_def, :meta_eval, :metaclass, :methods, :object_id]
        (instance_methods.map{|m| m.to_sym} - keep).each { |m| undef_method m unless m.to_s =~ /^__/ }

        def initialize
          @parsed_contexts = {}
        end

        attr_reader :parsed_contexts

        def method_missing(name, *args, &block)
          super unless block_given?
          @parsed_contexts[name] = block
          meta_def(name) { block }
        end

      end
    end
  end
end
