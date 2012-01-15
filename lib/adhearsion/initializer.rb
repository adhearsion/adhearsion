require 'adhearsion/punchblock_plugin'

module Adhearsion
  class Initializer

    extend ActiveSupport::Autoload

    autoload :Logging

    class << self
      def get_rules_from(location)
        location = File.join location, ".ahnrc" if File.directory? location
        File.exists?(location) ? YAML.load_file(location) : nil
      end

      def start(*args, &block)
        new(*args, &block).start
      end

      def start_from_init_file(file, ahn_app_path)
        return if defined?(@@started) && @@started
        start ahn_app_path, :loaded_init_files => file
      end

    end

    attr_reader :path, :daemon, :pid_file

    # Creation of pid_files
    #
    #  - You may want to have Adhearsion create a process identification
    #    file when it boots so that a crash monitoring program such as
    #    Monit can reboot if necessary or so the init script can kill it
    #    for system shutdowns.
    #  - To have Adhearsion create a pid file in the default location (i.e.
    #    AHN_INSTALL_DIR/adhearsion.pid), supply :pid_file with 'true'. Otherwise
    #    one is not created UNLESS it is running in daemon mode, in which
    #    case one is created. You can force Adhearsion to not create one
    #    even in daemon mode by supplying "false".
    def initialize(path = nil, options = {})
      @@started = true
      @path     = path
      @mode     = options[:mode]
      @pid_file = options[:pid_file].nil? ? ENV['PID_FILE'] : options[:pid_file]
      @loaded_init_files  = options[:loaded_init_files]
      Adhearsion.ahn_root = path
    end

    def start
      resolve_pid_file_path
      load_lib_folder
      load_plugins_methods
      load_config
      initialize_log_paths
      daemonize! if should_daemonize?
      launch_console if need_console?
      switch_to_root_directory
      catch_termination_signal
      create_pid_file if pid_file
      start_logging
      initialize_exception_logger
      init_plugins

      logger.info "Adhearsion v#{Adhearsion::VERSION} initialized!"
      Adhearsion::Process.booted

      trigger_after_initialized_hooks
      join_important_threads
      self
    end

    def default_pid_path
      File.join Adhearsion.config.root, 'adhearsion.pid'
    end

    def resolve_pid_file_path
      @pid_file = if pid_file.equal?(true) then default_pid_path
        elsif pid_file then pid_file
        elsif pid_file.equal?(false) then nil
        # FIXME @pid_file = @daemon? Assignment or equality? I'm assuming equality.
        else @pid_file = (@mode == :daemon) ? default_pid_path : nil
      end
    end

    def resolve_log_file_path
      _log_file = Adhearsion.config.platform.logging.outputters
      _log_file = _log_file[0] if _log_file.is_a?(Array)
      _log_file = File.expand_path(Adhearsion.config.root.dup.concat("/").concat(_log_file)) unless _log_file.start_with?("/")
      _log_file
    end

    def switch_to_root_directory
      Dir.chdir Adhearsion.config.root
    end

    def catch_termination_signal
      %w'INT TERM'.each do |process_signal|
        trap process_signal do
          Adhearsion::Process.shutdown
        end
      end

      trap 'QUIT' do
        Adhearsion::Process.hard_shutdown
      end

      trap 'ABRT' do
        Adhearsion::Process.force_stop
      end
    end

    ##
    # Loads files in application lib folder
    # @return [Boolean] if files have been loaded (lib folder is configured to not nil and actually exists)
    def load_lib_folder
      unless Adhearsion.config.platform.lib.nil?
        lib_folder = "#{Adhearsion.config.platform.root}/#{Adhearsion.config.platform.lib}"
        if File.directory? lib_folder
          Dir.chdir lib_folder do
            rbfiles = File.join "**", "*.rb"
            Dir.glob(rbfiles).each do |file|
              require "#{lib_folder}/#{file}"
            end
          end
          true
        else
          false
        end
      else
        false
      end
    end

    def load_config
      require "#{Adhearsion.config.root}/config/adhearsion.rb"
    end

    def init_get_logging_appenders
      @file_loggers ||= memoize_logging_appenders
    end

    def memoize_logging_appenders
      appenders = Array(Adhearsion.config.platform.logging.outputters.dup)
      # Any filename in the outputters array is mapped to a ::Logging::Appenders::File instance
      appenders.map! do |a|
        case a
        when String
          f = File.expand_path(Adhearsion.config.root.dup.concat("/").concat(a)) unless a.start_with?("/")
          ::Logging.appenders.file(f,
            :layout => ::Logging.layouts.pattern(
              :pattern => Adhearsion::Logging.adhearsion_pattern
            )
          )
        else
         a
        end
      end

      if should_daemonize?
        appenders
      else
        stdout = ::Logging.appenders.stdout(
                            'stdout',
                            :layout => ::Logging.layouts.pattern(
                              :pattern => Adhearsion::Logging.adhearsion_pattern,
                              :color_scheme => 'bright'
                            )
                          )
        appenders << stdout
      end
    end

    def load_plugins_methods
      Plugin.load_methods
    end

    def init_plugins
      Plugin.init_plugins
    end

    def should_daemonize?
      @mode == :daemon
    end

    def need_console?
      @mode == :console
    end

    def daemonize!
      logger.info "Daemonizing now! Creating #{pid_file}."
      extend Adhearsion::CustomDaemonizer
      daemonize resolve_log_file_path
    end

    def launch_console
      Adhearsion::Process.important_threads << Thread.new do
        begin
          puts "Starting console"
          Adhearsion::Console.run
          Adhearsion::Process.shutdown
        rescue Exception => e
          puts e.message
          puts e.backtrace.join("\n")
        end
      end
    end

    # Creates the relative paths associated to log files
    # i.e.
    # - log_file = "log/adhearsion.log"      => creates 'log' folder
    # - log_file = "log/test/adhearsion.log" => creates 'log' and 'log/test' folders
    def initialize_log_paths
      outputters = Array(Adhearsion.config.platform.logging.outputters)
      outputters.select{|o| o.is_a?(String)}.each do |o|
        o = o.split("/")
        unless o[0].empty? # only if relative path
          o.pop # not consider filename
          o.inject("") do |path, folder|
            path = path.concat(folder).concat("/")
            Dir.mkdir(path) unless File.directory? path
            path
          end
        end
      end
    end

    def start_logging
      outputters = init_get_logging_appenders
      Logging.start outputters, Adhearsion.config.platform.logging.level, Adhearsion.config.platform.logging.formatter
    end

    def initialize_exception_logger
      Events.register_handler :exception do |e|
        logger.error e
      end
    end

    def create_pid_file
      if pid_file
        File.open pid_file, 'w' do |file|
          file.puts ::Process.pid
        end

        Events.register_callback :shutdown do
          File.delete(pid_file) if File.exists?(pid_file)
        end
      end
    end

    def trigger_after_initialized_hooks
      Events.trigger_immediately :after_initialized
    end

    ##
    # This method will block Thread.main() until calling join() has returned for all Threads in Adhearsion::Process.important_threads.
    # Note: important_threads won't always contain Thread instances. It simply requires the objects respond to join().
    #
    def join_important_threads
      # Note: we're using this ugly accumulator to ensure that all threads have ended since IMPORTANT_THREADS will almost
      # certainly change sizes after this method is called.
      index = 0
      until index == Adhearsion::Process.important_threads.size
        begin
          Adhearsion::Process.important_threads[index].join
        rescue => e
          logger.error "Error after join()ing Thread #{Thread.inspect}. #{e.message}"
        ensure
          index = index + 1
        end
      end
    end

    InitializationFailedError = Class.new StandardError
  end
end
