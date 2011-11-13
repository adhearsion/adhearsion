module Adhearsion
  class DialPlan
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
          files = Adhearsion.config.files_from_setting("paths", "dialplan") if files.empty?
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
  end
end
