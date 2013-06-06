# encoding: utf-8

require 'adhearsion/punchblock_plugin'
require 'adhearsion/linux_proc_name'
require 'rbconfig'

module Adhearsion
  class Initializer

    class << self
      def start(*args, &block)
        new(*args, &block).start
      end
    end

    DEFAULT_PID_FILE_NAME = 'adhearsion.pid'

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
    def initialize(options = {})
      @@started = true
      @path     = path
      @mode     = options[:mode]
      @pid_file = options[:pid_file].nil? ? ENV['PID_FILE'] : options[:pid_file]
      @loaded_init_files  = options[:loaded_init_files]
      Adhearsion.ahn_root = '.'
    end

    def start
      catch :boot_aborted do
        resolve_pid_file_path
        load_lib_folder
        load_config_file
        initialize_log_paths

        if should_daemonize?
          daemonize!
        else
          create_pid_file
        end

        Adhearsion.statistics
        start_logging
        debugging_log
        launch_console if need_console?
        catch_termination_signal
        set_ahn_proc_name
        initialize_exception_logger
        update_rails_env_var
        init_plugins

        run_plugins
        trigger_after_initialized_hooks

        Adhearsion::Process.booted if Adhearsion.status == :booting

        logger.info "Adhearsion v#{Adhearsion::VERSION} initialized in \"#{Adhearsion.config.platform.environment}\"!" if Adhearsion.status == :running
      end

      # This method will block until all important threads have finished.
      # When it does, the process will exit.
      join_important_threads
      self
    end

    def debugging_items
      [
        "OS: #{RbConfig::CONFIG['host_os']} - RUBY: #{RUBY_ENGINE} #{RUBY_VERSION}",
        "Environment: #{ENV.inspect}",
        Adhearsion.config.description(:all),
        "Gem versions: #{Gem.loaded_specs.inject([]) { |c,g| c << "#{g[0]} #{g[1].version}" }}"
      ]
    end

    def debugging_log
      debugging_items.each do |item|
        logger.trace item
      end
    end

    def update_rails_env_var
      env = ENV['AHN_ENV']
      if env && Adhearsion.config.valid_environment?(env.to_sym)
        unless ENV['RAILS_ENV']
          logger.info "Copying AHN_ENV (#{env}) to RAILS_ENV"
          ENV['RAILS_ENV'] = env
        end
      else
        unless ENV['RAILS_ENV']
          env = Adhearsion.config.platform.environment.to_s
          ENV['AHN_ENV'] = env
          logger.info "Setting RAILS_ENV to \"#{env}\""
          ENV['RAILS_ENV'] = env
        end
      end
      logger.warn "AHN_ENV(#{ENV['AHN_ENV']}) does not match RAILS_ENV(#{ENV['RAILS_ENV']})!" unless ENV['RAILS_ENV'] == ENV['AHN_ENV']
      env
    end

    def default_pid_path
      File.join Adhearsion.config.root, DEFAULT_PID_FILE_NAME
    end

    def resolve_pid_file_path
      @pid_file = if pid_file.equal?(true)
        default_pid_path
      elsif pid_file.equal?(false)
        nil
      elsif pid_file
        File.expand_path pid_file
      else
        should_daemonize? ? default_pid_path : nil
      end
    end

    def resolve_log_file_path
      _log_file = Adhearsion.config.platform.logging.outputters
      _log_file = _log_file[0] if _log_file.is_a?(Array)
      _log_file = File.expand_path(Adhearsion.config.root.dup.concat("/").concat(_log_file)) unless _log_file.start_with?("/")
      _log_file
    end

    def catch_termination_signal
      self_read, self_write = IO.pipe

      %w(INT TERM HUP ALRM ABRT).each do |sig|
        trap sig do
          self_write.puts sig
        end
      end

      Thread.new do
        begin
          while readable_io = IO.select([self_read])
            signal = readable_io.first[0].gets.strip
            handle_signal signal
          end
        rescue => e
          logger.error "Crashed reading signals"
          logger.error e
          exit 1
        end
      end
    end

    def handle_signal(signal)
      case signal
      when 'INT', 'TERM'
        logger.info "Received SIG#{signal}. Shutting down."
        Adhearsion::Process.shutdown
      when 'HUP'
        logger.debug "Received SIGHUP. Reopening logfiles."
        Adhearsion::Logging.reopen_logs
      when 'ALRM'
        logger.debug "Received SIGALRM. Toggling trace logging."
        Adhearsion::Logging.toggle_trace!
      when 'ABRT'
        logger.info "Received ABRT signal. Forcing stop."
        Adhearsion::Process.force_stop
      end
    end

    ##
    # Loads files in application lib folder
    # @return [Boolean] if files have been loaded (lib folder is configured to not nil and actually exists)
    def load_lib_folder
      return false if Adhearsion.config.platform.lib.nil?

      lib_folder = [Adhearsion.config.platform.root, Adhearsion.config.platform.lib].join '/'
      return false unless File.directory? lib_folder

      Dir.chdir lib_folder do
        rbfiles = File.join "**", "*.rb"
        Dir.glob(rbfiles).each do |file|
          require "#{lib_folder}/#{file}"
        end
      end
      true
    end

    def load_config_file
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
            ),
           :auto_flushing => 2,
           :flush_period => 2
          )
        else
         a
        end
      end

      if should_daemonize?
        appenders
      else
        appenders += Adhearsion::Logging.default_appenders
      end
    end

    def init_plugins
      Plugin.init_plugins
    end

    def run_plugins
      Plugin.run_plugins
    end

    def should_daemonize?
      @mode == :daemon
    end

    def need_console?
      @mode == :console
    end

    def daemonize!
      logger.info "Daemonizing now!"
      Adhearsion::CustomDaemonizer.daemonize resolve_log_file_path do |pid|
        create_pid_file pid
      end
    end

    def launch_console
      Adhearsion::Process.important_threads << Thread.new do
        catching_standard_errors do
          Adhearsion::Console.run
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
      Adhearsion::Logging.start outputters, Adhearsion.config.platform.logging.level, Adhearsion.config.platform.logging.formatter
    end

    def initialize_exception_logger
      Events.register_handler :exception do |e, l|
        (l || logger).error e
      end
    end

    def create_pid_file(pid = nil)
      return unless pid_file

      logger.debug "Creating PID file #{pid_file}"

      File.open pid_file, 'w' do |file|
        file.puts pid || ::Process.pid
      end

      Events.register_callback :shutdown do
        File.delete(pid_file) if File.exists?(pid_file)
      end
    end

    def set_ahn_proc_name
      Adhearsion::LinuxProcName.set_proc_name Adhearsion.config.platform.process_name
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
          logger.error "Error after joining Thread #{Thread.inspect}. #{e.message}"
        ensure
          index = index + 1
        end
      end
    end

    InitializationFailedError = Class.new Adhearsion::Error
  end
end
