# encoding: utf-8

require 'fileutils'
require 'adhearsion/script_ahn_loader'
require 'thor'
require 'adhearsion/generators/controller/controller_generator'
require 'adhearsion/generators/plugin/plugin_generator'
Adhearsion::Generators.add_generator :controller, Adhearsion::Generators::ControllerGenerator
Adhearsion::Generators.add_generator :plugin, Adhearsion::Generators::PluginGenerator

# @private
class Thor
  class Task
    protected

    def sans_backtrace(backtrace, caller)
      saned  = backtrace.reject { |frame| frame =~ FILE_REGEXP || (frame =~ /\.java:/ && RUBY_PLATFORM =~ /java/) }
      saned -= caller
    end
  end
end

module Adhearsion
  module CLI
    class PluginCommand < Thor

      namespace :plugin

      desc "create_github_hook", "Creates ahnhub hook to track github commits"
      def create_github_hook
        get_github_vals

        generate_github_webhook
      end

      desc "create_rubygem_hook", "Creates ahnhub hook to track rubygem updates"
      def create_rubygem_hook
        get_rubygem_vals

        `curl -H 'Authorization:#{ENV['RUBYGEM_AUTH']}' \
        -F 'gem_name=#{ENV['RUBYGEM_NAME']}' \
        -F 'url=http://www.ahnhub.com/gem' \
        https://rubygems.org/api/v1/web_hooks/fire`
      end

      desc "create_ahnhub_hooks", "Creates ahnhub hooks for both a rubygem and github repo"
      def create_ahnhub_hooks
        create_github_hooks
        create_rubygem_hooks
      end

      def self.banner(task, namespace = true, subcommand = false)
        "#{basename} #{task.formatted_usage(self, true, subcommand)}"
      end

      protected

      def get_rubygem_vals
        ENV['RUBYGEM_NAME'] ||= ask "What's the rubygem name?"
        ENV['RUBYGEM_AUTH'] ||= ask "What's your authorization key for Rubygems?"
      end

      def get_github_vals
        ENV['GITHUB_USERNAME'] ||= ask "What's your github username?"
        ENV['GITHUB_PASSWORD'] ||= ask "What's your github password?"
        ENV['GITHUB_REPO']     ||= ask "Please enter the owner and repo (for example, 'adhearsion/new-plugin'): "
      end

      def github_repo_owner
        ENV['GITHUB_REPO'].split('/')[0]
      end

      def github_repo_name
        ENV['GITHUB_REPO'].split('/')[1]
      end

      def generate_github_webhook
        require 'net/http'

        uri = URI("https://api.github.com/repos/#{github_repo_owner}/#{github_repo_name}/hooks")
        req = Net::HTTP::Post.new(uri.to_s)

        req.basic_auth ENV['GITHUB_USERNAME'], ENV['GITHUB_PASSWORD']
        req.body = {
          name:   "web",
          active: true,
          events: ["push", "pull_request"],
          config: {url: "http://ahnhub.com/github"}
        }.to_json

        req["content-type"] = "application/json"
        Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
          response = http.request(req)
          puts response.body
        end
      end
    end # PluginCommand

    class AhnCommand < Thor
      map %w(-h --h -help --help) => :help
      map %w(-v --v -version --version) => :version
      map %w(-) => :start

      register ::Adhearsion::CLI::PluginCommand, 'plugin', 'plugin <command>', 'Plugin Tasks.'

      check_unknown_options!

      def self.exit_on_failure?
        true
      end

      desc "create /path/to/directory", "Create a new Adhearsion application under the given path"
      def create(path)
        require 'adhearsion/generators/app/app_generator'
        Generators::AppGenerator.start
      end

      desc "generate [generator_name] arguments", Generators.help
      def generate(generator_name = nil, *args)
        if generator_name
          Generators.invoke generator_name
        else
          help 'generate'
        end
      end

      desc "version", "Shows Adhearsion version"
      def version
        say "Adhearsion v#{Adhearsion::VERSION}"
        exit 0
      end

      desc "start </path/to/directory>", "Start the Adhearsion server in the foreground with a console"
      method_option :noconsole, type: :boolean, aliases: %w{--no-console}
      def start(path = nil)
        start_app path, options[:noconsole] ? :simple : :console
      end

      desc "daemon </path/to/directory>", "Start the Adhearsion server in the background"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def daemon(path = nil)
        start_app path, :daemon, options[:pidfile]
      end

      desc "stop </path/to/directory>", "Stop a running Adhearsion server"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def stop(path = nil)
        execute_from_app_dir! path

        pid_file = if options[:pidfile]
          File.exists?(File.expand_path(options[:pidfile])) ?
            options[:pidfile] :
            File.join(path, options[:pidfile])
        else
          path = Dir.pwd
          File.join path, Adhearsion::Initializer::DEFAULT_PID_FILE_NAME
        end
        pid_file = File.expand_path pid_file

        begin
          pid = File.read(pid_file).to_i
        rescue
          raise PIDReadError, pid_file
        end

        raise PIDReadError, pid_file if pid.nil?

        say "Stopping Adhearsion server at #{path} with pid #{pid}"
        waiting_timeout = Time.now + 15
        begin
          ::Process.kill "TERM", pid
          sleep 0.25 while process_exists?(pid) && Time.now < waiting_timeout
          ::Process.kill "KILL", pid
        rescue Errno::ESRCH
        end

        File.delete pid_file if File.exists? pid_file
      end

      desc "restart </path/to/directory>", "Restart the Adhearsion server"
      method_option :pidfile, :type => :string, :aliases => %w(--pid-file)
      def restart(path = nil)
        execute_from_app_dir! path
        begin
          invoke :stop
        rescue PIDReadError => e
          puts e.message
        end
        invoke :daemon
      end

      protected

      def start_app(path, mode, pid_file = nil)
        execute_from_app_dir! path
        say "Starting Adhearsion server at #{Dir.pwd}"
        Adhearsion::Initializer.start :mode => mode, :pid_file => pid_file
      end

      def execute_from_app_dir!(path)
        return if in_app? and running_script_ahn?

        path ||= Dir.pwd if in_app?

        raise PathRequired, ARGV[0] if path.nil? or path.empty?

        Dir.chdir path do
          raise PathInvalid, path unless ScriptAhnLoader.in_ahn_application?
          args = ARGV.dup
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

     class UnknownGeneratorError < Thor::Error
      def initialize(gentype)
        puts "Please specify generator to use (#{Adhearsion::Generators.mappings.keys.join(", ")})"
        super "Unknown command: #{gentype}"
      end
    end

    class PathInvalid < Thor::Error
      def initialize(path)
        super "Directory #{path} does not belong to an Adhearsion project!"
      end
    end

    class PIDReadError < Thor::Error
      def initialize(path)
        super "Could not read pid from the file #{path}"
      end
    end
  end
end
