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
      Adhearsion.status = :starting

      resolve_pid_file_path
      resolve_log_file_path
      load_plugins_methods
      daemonize! if should_daemonize?
      launch_console if need_console?
      switch_to_root_directory
      catch_termination_signal
      create_pid_file if pid_file
      bootstrap_rc
      initialize_log_file
      start_logging
      initialize_exception_logger
      load_all_init_files
      init_events_file
      init_plugins

      logger.info "Adhearsion v#{Adhearsion::VERSION} initialized!"
      Adhearsion.status = :running

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
      @ahn_app_log_directory = "#{Adhearsion.config.root}/log"
      @log_file = File.expand_path(ahn_app_log_directory + "/adhearsion.log")
    end

    def switch_to_root_directory
      Dir.chdir Adhearsion.config.root
    end

    def catch_termination_signal
      %w'INT TERM'.each do |process_signal|
        trap process_signal do
          Adhearsion.shutdown!
        end
      end
    end

    ##
    # This step in the initialization process loads the .ahnrc in the given app folder. With the information in .ahnrc, we
    # can continue the initialization knowing where certain files are specifically.
    #
    def bootstrap_rc
      rules = self.class.get_rules_from Adhearsion.config.root

      Adhearsion.config.ahnrc = rules

      # DEPRECATION: Check if the old paths format is being used. If so, abort and notify.
      if rules.has_key?("paths") && rules["paths"].kind_of?(Hash)
        paths = rules["paths"].each_pair do |key,value|
          if value.kind_of?(Hash)
            if value.has_key?("directory") || value.has_key?("pattern")
              puts
              puts *caller
              puts

              abort <<-WARNING
Deprecation Warning
-------------------
The (hidden) .ahnrc file in this app is of an older format and needs to be fixed.

There is a rake task to automatically fix it or you can do it manually. Note: it's
best if you do it manually so you can retain the YAML comments in your .ahnrc file.

The rake task is called "deprecations:fix_ahnrc_path_format".

To do it manually, find all entries in the "paths" section of your ".ahnrc" file
which look like the following:

paths:
  key_name_could_be_anything:
    directory: some_folder
    pattern: *.rb

Note: the "models" section had this syntax before:

models:
  directory: models
  pattern: "*.rb"

The NEW syntax is as follows (using models as an example):

models: models/*.rb

This new format is much cleaner.

Adhearsion will abort until you fix this. Sorry for the incovenience.
              WARNING
            end
          end
        end
      end

      gems = rules['gems']
      if gems.kind_of?(Hash) && gems.any? && respond_to?(:gem)
        gems.each_pair do |gem_name,properties_hash|
          if properties_hash && properties_hash["version"]
            gem gem_name, properties_hash["version"]
          else
            gem gem_name
          end
          if properties_hash
            case properties_hash["require"]
              when Array
                properties_hash["require"].each { |lib| require lib }
              when String
                require properties_hash["require"]
            end
          end
        end
      end
    end

    def load_all_init_files
      init_files_from_rc = Adhearsion.config.files_from_setting("paths", "init").map { |file| File.expand_path(file) }
      already_loaded_init_files = Array(@loaded_init_files).map { |file| File.expand_path(file) }
      puts init_files_from_rc - already_loaded_init_files
      (init_files_from_rc - already_loaded_init_files).each { |init| load init }
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

    def init_events_file
      Adhearsion.config.files_from_setting("paths", "events").each do |file|
        require file
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
      Thread.new do
        begin
          puts "Starting console"
          Adhearsion::Console.run
          Adhearsion.shutdown!
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
      Logging.start init_get_logging_appenders
    end

    def initialize_exception_logger
      Events.register_handler :exception do |e|
        logger.error e
      end
    end

    def create_pid_file
      if pid_file
        File.open pid_file, 'w' do |file|
          file.puts Process.pid
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
    # This method will block Thread.main() until calling join() has returned for all Threads in IMPORTANT_THREADS.
    # Note: IMPORTANT_THREADS won't always contain Thread instances. It simply requires the objects respond to join().
    #
    def join_important_threads
      # Note: we're using this ugly accumulator to ensure that all threads have ended since IMPORTANT_THREADS will almost
      # certainly change sizes after this method is called.
      index = 0
      until index == IMPORTANT_THREADS.size
        begin
          IMPORTANT_THREADS[index].join
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
