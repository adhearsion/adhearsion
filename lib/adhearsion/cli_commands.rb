require 'fileutils'
require 'adhearsion/script_ahn_loader'
require 'thor'

module Adhearsion
  module CLI
    class AhnCommand < Thor
      TRY_HELP_MSG = "\nTry: #{File.basename($0)} help"
      VALID_START_MODES = %w(daemon console)

      map %w(-h --h -help --help) => :help
      map %w(-v --v -version --version) => :version

      check_unknown_options!

      desc "create /path/to/directory", "Create a new Adhearsion application under the given path"
      def create(path)
        require 'adhearsion/generators'
        require 'adhearsion/generators/app/app_generator.rb'
        Adhearsion::Generators::AppGenerator.start
      end

      desc "version", "Shows Adhearsion version"
      def version
        say "Adhearsion v#{Adhearsion::VERSION}"
        exit(0)
      end

      desc "start [console|daemon] </path/to/directory>", "Start the Adhearsion server"
      long_desc <<-DESC
      Start the Adhearsion server

          console -- starts the interactive Adhearsion CLI\n
          daemon -- runs the server in the background
      DESC
      method_option :console, :type => :boolean
      method_option :daemon, :type => :boolean
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def start(*args)
        mode = nil
        pid_file = options[:pidfile]
        puts "ARGV: #{ARGV.join(' ')}"
        puts "ARGV SIZE: #{ARGV.size}"
        puts "args SIZE: #{args.size}"
        puts options.inspect
        puts "pid file #{pid_file.inspect}"
        #puts "path: #{path.inspect}"
        puts "args: #{args.inspect}"
        puts "mode: #{mode.inspect}"

        raise CLIException, "Invalid start mode requested!" + TRY_HELP_MSG + " start" \
          if options[:console] and options[:daemon]

        mode = if options[:console]
                 :console
               elsif options[:daemon]
                 :daemon
               else
                 :foreground
               end

        puts "mode: #{mode.inspect}"

        puts "args.first #{args.first}"

        if args.size > 2
          raise CLIException, "Too many arguments supplied!" + TRY_HELP_MSG + " start" \
        elsif args == 2 and args.first =~ /foreground|daemon|console/
          path = args.last
          mode = args.first.to_sym
        elsif args == 1
          path = args.last
        else
          raise CLIException, "Invalid start mode requested: #{args.first}"
        end

        execute_from_app_dir!(path, ARGV) unless
          ScriptAhnLoader.in_ahn_application? or
          ScriptAhnLoader.in_ahn_application_subdirectory?

        raise PathInvalid, path unless ScriptAhnLoader.in_ahn_application?
        Adhearsion::Initializer.start path, :mode => mode, :pid_file => pid_file
      end

      protected
      def method_missing(action, *args)
        raise UnknownCommand, [action, *args, TRY_HELP_MSG] * " "
      end

      def execute_from_app_dir!(app_path, *args)
        Dir.chdir app_path do
          ScriptAhnLoader.exec_script_ahn! args
        end
      end

    end # AhnCommand

    class CLIException < Thor::Error; end
    class UnknownCommand < CLIException
      def initialize(cmd)
        super "Unknown command: #{cmd}"
      end
    end

    class PathInvalid < CLIException
      def initialize(path)
        super "Directory #{path} does not belong to an Adhearsion project!"
      end
    end
  end
end
