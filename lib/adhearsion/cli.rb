require 'fileutils'

module Adhearsion
  module CLI
    module AhnCommand
      USAGE = <<USAGE
Usage:
   ahn create /path/to/directory
   ahn start [daemon] [/path/to/directory]
   ahn version|-v|--v|-version|--version
   ahn help|-h|--h|--help|-help

   ahn  enable component COMPONENT_NAME
   ahn disable component COMPONENT_NAME
   ahn  create component COMPONENT_NAME
USAGE

      def self.execute!
        CommandHandler.send(*parse_arguments)
      rescue CommandHandler::CLIException => error
        fail_and_print_usage error
      end

      ##
      # Provides a small abstraction of Kernel::abort().
      #
      def self.fail_and_print_usage(error)
        Kernel.abort "#{error.message}\n\n#{USAGE}"
      end

      def self.parse_arguments(args=ARGV.clone)
        action = args.shift
        case action
          when /^-?-?h(elp)?$/, nil   then [:help]
          when /^-?-?v(ersion)?$/     then [:version]
          when "create"
            [:create, *args]
          when 'start'
            pid_file_regexp = /^--pid-file=(.+)$/
            if args.size > 3
              fail_and_print_usage "Too many arguments supplied!" if args.size > 3
            elsif args.size == 3
              fail_and_print_usage "Unrecognized final argument #{args.last}" unless args.last =~ pid_file_regexp
              pid_file = args.pop[pid_file_regexp, 1]
            else
              pid_file = nil
            end

            if args.first == 'daemon' && args.size == 2
              path   = args.last
              daemon = true
            elsif args.size == 1
              path, daemon = args.first, false
            else
              fail_and_print_usage "Invalid format for the start CLI command!"
            end
            [:start, path, daemon, pid_file]
          when '-'
            [:start, Dir.pwd]
          when "enable", "disable"
            if args.size == 1
              raise CommandHandler::UnknownCommand, "Must supply an argument for what you wish to #{action}"
            elsif args.size == 2
              [action, *args]
            else
              raise CommandHandler::UnknownCommand, "Too many arguments supplied!"
            end
          else
            [action, *args]
        end
      end

      module CommandHandler
        class << self

          def create(*args)
            if args.size.zero?
              raise CommandHandler::UnknownCommand.new("Must specify something to create!")
            elsif args.size == 1
              # We're creating a project
              path = args.first
              require 'rubigen'
              require 'rubigen/scripts/generate'
              source = RubiGen::PathSource.new(:application,
                File.join(File.dirname(__FILE__), "../../app_generators"))
              RubiGen::Base.reset_sources
              RubiGen::Base.append_sources source
              RubiGen::Scripts::Generate.new.run([path], :generator => 'ahn')
            elsif args.size == 2
              # We're creating a feature (e.g. a component)
              feature_type, component_name = args

              if feature_type != "component"
                # At the moment, only components can be created.
                raise CommandHandler::UnknownCommand.new("Don't know how to create '#{feature_type}'")
              end

              if component_name !~ /^[a-z][\w_]+$/
                raise CommandHandler::ComponentError.new("Component name must be lowercase alphanumeric characters " +
                    "and begin with a character")
              end

              app_path = PathString.from_application_subdirectory Dir.pwd

              raise PathInvalid.new(Dir.pwd) if app_path.nil?

              new_component_dir = app_path + "/components/#{component_name}"
              raise ComponentError.new("Component #{component_name} already exists!") if File.exists?(new_component_dir)

              # Everything's good. Let's create the component
              Dir.mkdir new_component_dir
              File.open(new_component_dir + "/#{component_name}.rb","w") do |file|
                file.puts <<-RUBY
# See http://docs.adhearsion.com for more information on how to write components or
# look at the examples in newly-created projects.
                RUBY
              end
              File.open(new_component_dir + "/#{component_name}.yml","w") do |file|
                file.puts '# You can use this file for component-specific configuration.'
              end
              puts "Created blank component '#{component_name}' at components/#{component_name}"
            else
              raise CommandHandler::UnknownCommand.new("Provided too many arguments to 'create'")
            end
          end

          def start(path, daemon=false, pid_file=nil)
            raise PathInvalid, path unless File.exists? path + "/.ahnrc"
            Adhearsion::Initializer.start path, :daemon => daemon, :pid_file => pid_file
          end

          def version
            puts "Adhearsion v#{Adhearsion::VERSION::STRING}"
          end

          def help
            puts USAGE
          end

          def enable(type, name)
            case type
              when "component"
                app_path = PathString.from_application_subdirectory Dir.pwd
                if app_path
                  disabled_component_path = File.join app_path, "components", "disabled", name
                  enabled_component_path  = File.join app_path, "components", name
                  if File.directory? disabled_component_path
                    FileUtils.mv disabled_component_path, enabled_component_path
                    puts "Enabled component #{name}"
                  else
                    raise ComponentError.new("There is no components/disabled directory!")
                  end
                else
                  raise PathInvalid.new(Dir.pwd)
                end
              else
                raise UnknownCommand.new("enable #{type}")
            end
          end

          def disable(type, name)
            case type
              when "component"
                app_path = PathString.from_application_subdirectory Dir.pwd
                if app_path
                  disabled_dir = File.join app_path, "components", "disabled"

                  disabled_component_path = File.join disabled_dir, name
                  enabled_component_path  = File.join app_path, "components", name

                  Dir.mkdir disabled_dir unless File.directory?(disabled_dir)

                  if File.directory? enabled_component_path
                    if File.directory?(disabled_component_path)
                      raise ComponentError.new("There is already a disabled component at #{disabled_component_path}")
                    else
                      FileUtils.mv enabled_component_path, disabled_component_path
                      puts "Disabled component #{name}"
                    end
                  else
                    raise ComponentError.new("Could not find component #{name} at #{enabled_component_path} !")
                  end
                else
                  raise PathInvalid.new(Dir.pwd)
                end
              else
                raise UnknownCommand.new("disable #{type}")
            end
          end

          def method_missing(action, *args)
            raise UnknownCommand, [action, *args] * " "
          end

          private

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
