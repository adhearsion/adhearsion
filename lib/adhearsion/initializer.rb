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

    attr_reader :path, :daemon, :pid_file, :log_file, :ahn_app_log_directory

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
    def initialize(path=nil, options={})
      @@started = true
      @path     = path
      @mode     = options[:mode]
      @pid_file = options[:pid_file].nil? ? ENV['PID_FILE'] : options[:pid_file]
      @loaded_init_files  = options[:loaded_init_files]
      Adhearsion.ahn_root = path
    end

    def start
      resolve_pid_file_path
      resolve_log_file_path
      load_lib_folder
      load_plugins_methods
      load_config
      initialize_log_file
      daemonize! if should_daemonize?
      launch_console if need_console?
      switch_to_root_directory
      catch_termination_signal
      create_pid_file if pid_file
      start_logging
      logger.info "Loaded config in <#{Adhearsion.config.platform.environment}> environment"
      initialize_exception_logger
      update_rails_env_var
      init_plugins

      logger.info "Adhearsion v#{Adhearsion::VERSION} initialized!"
      Adhearsion::Process.booted

      trigger_after_initialized_hooks
      join_important_threads
      self
    end

    def update_rails_env_var
      env = ENV['AHN_ENV']
      if env && Adhearsion.config.valid_environment?(env.to_sym)
        if ENV['RAILS_ENV'] != env
          logger.warn "Updating AHN_RAILS variable to <#{env}>"
          ENV['RAILS_ENV'] = env
        else
          logger.info "Using the configured value for RAILS_ENV : <#{env}>"
        end
      else
        env = ENV['RAILS_ENV']
        unless env
          env = Adhearsion.config.platform.environment.to_s
          logger.info "Defining AHN_RAILS variable to <#{env}>"
          ENV['RAILS_ENV'] = env
        else
          logger.info "Using the configured value for RAILS_ENV : <#{env}>"
        end
      end
      env
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
      @ahn_app_log_directory = "#{Adhearsion.config.root}/log"
      @log_file = File.expand_path(ahn_app_log_directory + "/adhearsion.log")
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
      file_logger = ::Logging.appenders.file(log_file,
                                              :layout => ::Logging.layouts.pattern(
                                                :pattern => Adhearsion::Logging.adhearsion_pattern
                                              )
                                            )

      if should_daemonize?
        file_logger
      else
        stdout = ::Logging.appenders.stdout(
                            'stdout',
                            :layout => ::Logging.layouts.pattern(
                              :pattern => Adhearsion::Logging.adhearsion_pattern,
                              :color_scheme => 'bright'
                            )
                          )
        [file_logger, stdout]
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
      daemonize log_file
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

    def initialize_log_file
      Dir.mkdir(ahn_app_log_directory) unless File.directory? ahn_app_log_directory
    end

    def start_logging
      outputters = Adhearsion.config.platform.logging.outputters.nil? ? init_get_logging_appenders : Adhearsion.config.platform.logging.outputters
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
