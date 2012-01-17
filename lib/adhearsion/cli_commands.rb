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

      def self.exit_on_failure?
        true
      end

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
      def start(path = nil)
        start_app path, :console
      end

      desc "daemon </path/to/directory>", "Start the Adhearsion server in the background"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def daemon(path = nil)
        start_app path, :daemon, options[:pidfile]
      end

      desc "stop </path/to/directory>", "Stop a running Adhearsion server"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def stop(path = nil)
        execute_from_app_dir! path, ARGV

        pid_file = if options[:pidfile]
          File.expand_path File.exists?(File.expand_path(options[:pidfile])) ?
          options[:pidfile] :
          File.join(path, options[:pidfile])
        else
          path + '/adhearsion.pid'
        end

        begin
          pid = File.read(pid_file).to_i
        rescue
          raise CLIException, "Could not read pid file #{pid_file}"
        end

        raise CLIException, "Could not read pid" if pid.nil?

        say "Stopping Adhearsion server at #{path} with pid #{pid}"
        waiting_timeout = Time.now + 15
        begin
          ::Process.kill "TERM", pid
          sleep 0.25 while process_exists?(pid) && Time.now < waiting_timeout
          ::Process.kill "KILL", pid
        rescue Errno::ESRCH
        end
      end

      desc "restart </path/to/directory>", "Restart the Adhearsion server"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def restart(path = nil)
        execute_from_app_dir! path, ARGV
        invoke :stop
        invoke :daemon
      end

      protected

      def start_app(path, mode, pid_file = nil)
        execute_from_app_dir! path, ARGV
        say "Starting Adhearsion server at #{path}"
        Adhearsion::Initializer.start :mode => mode, :pid_file => pid_file
      end

      def execute_from_app_dir!(path, *args)
        return if in_app? and running_script_ahn?

        path ||= '.' if in_app?

        raise PathRequired, ARGV[0] if path.nil? or path.empty?
        raise PathInvalid, path unless ScriptAhnLoader.in_ahn_application?(path)

        Dir.chdir path do
          args.flatten!
          args[1] = '.'
          ScriptAhnLoader.exec_script_ahn! args
        end
      end

      def running_script_ahn?
        $0.to_s == "script/ahn"
      end

      def in_app?
        ScriptAhnLoader.in_ahn_application? or ScriptAhnLoader.in_ahn_application_subdirectory?
      end

      def process_exists?(pid = nil)
        # FIXME: Raise some error here
        return false if pid.nil?
        `ps -p #{pid} | sed -e '1d'`.strip.empty?
      end

      def method_missing(action, *args)
        help
        raise UnknownCommand, [action, *args] * " "
      end
    end # AhnCommand

    class UnknownCommand < Thor::Error
      def initialize(cmd)
        super "Unknown command: #{cmd}"
      end
    end

    class PathRequired < Thor::Error
      def initialize(cmd)
        super "A valid path is required for #{cmd}, unless run from an Adhearson app directory"
      end
    end

    class PathInvalid < Thor::Error
      def initialize(path)
        super "Directory #{path} does not belong to an Adhearsion project!"
      end
    end
  end
end
