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

   ahn  enable component COMPONENT_NAME
   ahn disable component COMPONENT_NAME
   ahn  create component COMPONENT_NAME
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

              if app_path.nil?
                new_component_dir = File.join Dir.pwd, component_name
              else
                puts "Adhearsion application detected. Creating new component at components/#{component_name}"
                new_component_dir = File.join app_path, "components", component_name
              end

              raise ComponentError.new("Component #{component_name} already exists!") if File.exists?(new_component_dir)

              # Everything's good. Let's create the component
              Dir.mkdir new_component_dir

              # Initial component code file
              Dir.mkdir File.join(new_component_dir, "lib")
              fn = File.join("lib", "#{component_name}.rb")
              puts "- #{fn}: Initial component code file"
              File.open(File.join(new_component_dir, fn),"w") do |file|
                file.puts <<-RUBY
# See http://docs.adhearsion.com for more information on how to write components or
# look at the examples in newly-created projects.
                RUBY
              end

              # Component configuration
              Dir.mkdir File.join(new_component_dir, "config")
              fn = File.join("config", "#{component_name}.yml")
              puts "- #{fn}: Example component configuration YAML"
              File.open(File.join(new_component_dir, fn),"w") do |file|
                file.puts '# You can use this file for component-specific configuration.'
              end

              # Component example gemspec
              fn = File.join("#{component_name}.gemspec")
              puts "- #{fn}: Example component gemspec"
              File.open(File.join(new_component_dir, fn), "w") do |file|
                file.puts <<-RUBY
GEM_FILES = %w{
  #{component_name}.gemspec
  lib/#{component_name}.rb
  config/#{component_name}.yml
}

Gem::Specification.new do |s|
  s.name = "#{component_name}"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Your Name Here!"]

  s.date = Date.today.to_s
  s.description = "This Adhearsion component gem has not yet been described."
  s.email = "noreply@example.com"

  s.files = GEM_FILES

  s.has_rdoc = false
  s.homepage = "http://adhearsion.com"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.2.0"
  s.summary = "This Adhearsion component gem has no summary."

  s.specification_version = 2
end
                RUBY
              end

              # Component example spec
              Dir.mkdir File.join(new_component_dir, "spec")
              fn = File.join("spec", "#{component_name}_spec.rb")
              puts "- #{fn}: Example component spec"
              File.open(File.join(new_component_dir, fn), "w") do |file|
                file.puts <<-RUBY
require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require

require 'adhearsion/component_manager/spec_framework'

component_name.upcase = ComponentTester.new("#{component_name}", File.dirname(__FILE__) + "/../..")
                RUBY
              end
              puts "Created blank component '#{component_name}' at #{new_component_dir}"
            else
              raise CommandHandler::UnknownCommand.new("Provided too many arguments to 'create'")
            end
          end

          def start(path, mode=:foreground, pid_file=nil)
            raise PathInvalid, path unless File.exists? path + "/.ahnrc"
            Adhearsion::Initializer.start path, :mode => mode, :pid_file => pid_file
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
                  disabled_components_path = File.join app_path, "components", "disabled"
                  enabled_component_path  = File.join app_path, "components", name
                  if File.directory? disabled_component_path
                    FileUtils.mv disabled_component_path, enabled_component_path
                    puts "Enabled component #{name}"
                  elsif File.directory? enabled_component_path
                    raise ComponentError.new("This component is already enabled.")
                  elsif !File.directory? disabled_components_path
                    raise ComponentError.new("There is no components/disabled directory!")
                  else
                    raise ComponentError.new("The requested component was not found.")
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
