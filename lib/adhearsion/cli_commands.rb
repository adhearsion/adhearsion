require 'fileutils'
require 'adhearsion/script_ahn_loader'
require 'thor'

module Adhearsion
  module CLI
    class AhnCommand < Thor
      map %w(-h --h -help --help) => :help
      map %w(-v --v -version --version) => :version
      map %w(-) => :start

      check_unknown_options!

      desc "create /path/to/directory", "Create a new Adhearsion application under the given path"
      def create(path)
        require 'adhearsion/generators'
        require 'adhearsion/generators/app/app_generator'
        Adhearsion::Generators::AppGenerator.start
      end

      desc "version", "Shows Adhearsion version"
      def version
        say "Adhearsion v#{Adhearsion::VERSION}"
        exit 0
      end

      desc "start </path/to/directory>", "Start the Adhearsion server in the foreground with a console"
      def start(*args)
        start_app args.first, :console
      end

      desc "daemon </path/to/directory>", "Start the Adhearsion server in the background"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def daemon(*args)
        start_app args.first, :daemon, options[:pidfile]
      end

      protected

      def start_app(path, mode, pid_file = nil)
        path ||= '.'
        execute_from_app_dir!(path, ARGV) unless
          ScriptAhnLoader.in_ahn_application? or
          ScriptAhnLoader.in_ahn_application_subdirectory?

        raise PathInvalid, path unless ScriptAhnLoader.in_ahn_application?
        Adhearsion::Initializer.start path, :mode => mode, :pid_file => pid_file
      end

      def method_missing(action, *args)
        help
        raise UnknownCommand, [action, *args] * " "
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
