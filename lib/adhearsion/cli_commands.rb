require 'fileutils'
require 'adhearsion/script_ahn_loader'

module Adhearsion
  module CLI
    module AhnCommand
      USAGE = <<USAGE
Usage:
   ahn create /path/to/directory
   ahn start [console|daemon] [/path/to/directory]
   ahn version|-v|--v|-version|--version
   ahn help|-h|--h|--help|-help
USAGE
      class << self

        def execute!
          if ARGV.first == 'start' && !(ScriptAhnLoader.in_ahn_application? || ScriptAhnLoader.in_ahn_application_subdirectory?)
            args = parse_arguments
            Dir.chdir args[1] do
              args = args.compact.map(&:to_s)
              args[1], args[2] = args[2], '.'
              ScriptAhnLoader.exec_script_ahn! args
            end
          end
          CommandHandler.send(*parse_arguments)
        rescue CommandHandler::CLIException => error
          fail_and_print_usage error
        end

        ##
        # Provides a small abstraction of Kernel::abort().
        #
        def fail_and_print_usage(error)
          Kernel.abort "#{error.message}\n\n#{USAGE}"
        end

        def parse_arguments(args=ARGV.clone)
          action = args.shift
          case action
          when /^-?-?h(elp)?$/, nil   then [:help]
          when /^-?-?v(ersion)?$/     then [:version]
          when "create"
            [:create, *args]
          when 'start'
            pid_file_regexp = /^--pid-file=(.+)$/
            if args.size > 3
              raise CommandHandler::CLIException, "Too many arguments supplied!" if args.size > 3
            else
              pid_file = nil
              pid_file = args.pop[pid_file_regexp, 1] if args.last =~ pid_file_regexp
              raise CommandHandler::CLIException, "Unrecognized final argument #{args.last}" unless args.size <= 2
            end

            if args.size == 2
              path   = args.last
              if args.first =~ /foreground|daemon|console/
                mode = args.first.to_sym
              else
                raise CommandHandler::CLIException, "Invalid start mode requested: #{args.first}"
              end
            elsif args.size == 1
              path, mode = args.first, :foreground
            else
              raise CommandHandler::CLIException, "Invalid format for the start CLI command!"
            end
            [:start, path, mode, pid_file]
          when '-'
            [:start, Dir.pwd]
          else
            [action, *args]
          end
        end
      end

      module CommandHandler
        class << self

          def create(*args)
            case args.size
            when 0
              raise CommandHandler::UnknownCommand.new("Must specify something to create!")
            when 1
              # We're creating a project
              path = args.first
              require 'rubigen'
              require 'rubigen/scripts/generate'
              source = RubiGen::PathSource.new :application, File.join(File.dirname(__FILE__), "../../app_generators")
              RubiGen::Base.reset_sources
              RubiGen::Base.append_sources source
              RubiGen::Scripts::Generate.new.run [path], :generator => 'ahn'
            else
              raise CommandHandler::UnknownCommand.new("Provided too many arguments to 'create'")
            end
          end

          def start(path, mode = :foreground, pid_file = nil)
            raise PathInvalid, path unless File.exists? path + "/.ahnrc"
            Adhearsion::Initializer.start path, :mode => mode, :pid_file => pid_file
          end

          def version
            puts "Adhearsion v#{Adhearsion::VERSION}"
          end

          def help
            puts USAGE
          end

          def method_missing(action, *args)
            raise UnknownCommand, [action, *args] * " "
          end
        end

        class CLIException < StandardError; end

        class UnknownCommand < CLIException
          def initialize(cmd)
            super "Unknown command: #{cmd}"
          end
        end

        class ComponentError < CLIException; end

        class UnknownProject < CLIException
          def initialize(project)
            super "Application #{project} does not exist! Have you installed it?"
          end
        end

        class PathInvalid < CLIException
          def initialize(path)
            super "Directory #{path} does not belong to an Adhearsion project!"
          end
        end
      end
    end
  end
end
