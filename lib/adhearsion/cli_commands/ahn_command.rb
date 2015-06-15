# encoding: utf-8

module Adhearsion
  module CLI
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
      method_option :empty, type: :boolean
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
        path = execute_from_app_dir! path
        say "Starting Adhearsion server at #{Dir.pwd}"
        Adhearsion::Initializer.start :console => !!options[:noconsole]
      end

      protected

      def execute_from_app_dir!(path)
        if in_app? and running_script_ahn?
          return Dir.pwd
        end

        path ||= Dir.pwd if in_app?

        raise PathRequired, ARGV[0] if path.nil? or path.empty?

        Dir.chdir path do
          raise PathInvalid, path unless ScriptAhnLoader.in_ahn_application?
          args = ARGV.dup
          args[1] = '.'
          ScriptAhnLoader.exec_script_ahn! args
        end
        path
      end

      def running_script_ahn?
        $0.to_s == "script/ahn"
      end

      def in_app?
        ScriptAhnLoader.in_ahn_application? or ScriptAhnLoader.in_ahn_application_subdirectory?
      end

      def method_missing(action, *args)
        help
        raise UnknownCommand, [action, *args] * " "
      end
    end
  end
end
