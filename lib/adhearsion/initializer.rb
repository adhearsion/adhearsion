module Adhearsion

  mattr_accessor :status

  class << self

    ##
    # Shuts down the framework.
    #
    def shutdown!
      if self.status == :stopping
        # This is the second shutdown request we've received while attempting
        # to shut down gracefully.  At this point, let's pull the plug...
        ahn_log.warning "Shutting down immediately at #{Time.now}"
        exit
      end
      ahn_log "Shutting down gracefully at #{Time.now}."
      self.status = :stopping
      Events.trigger_immediately :shutdown
      Events.stop!
      exit
    end

  end
  class PathString < String

    class << self

      ##
      # Will return a PathString for the application root folder to which the specified arbitrarily nested subfolder belongs.
      # It works by traversing parent directories looking for the .ahnrc file. If no .ahnrc is found, nil is returned.
      #
      # @param [String] folder The path to the directory which should be a
      # @return [nil] if the subdirectory does not belong to a parent Adhearsion app directory
      # @return [PathString] if a directory is found
      #
      def from_application_subdirectory(folder)
        folder = File.expand_path folder
        ahn_rc = nil

        until ahn_rc || folder == "/"
          possible_ahn_rc = File.join(folder, ".ahnrc")
          if File.exists?(possible_ahn_rc)
            ahn_rc = possible_ahn_rc
          else
            folder = File.expand_path(folder + "/..")
          end
        end
        ahn_rc ? new(folder) : nil
      end
    end

    attr_accessor :component_path, :dialplan_path, :log_path

    def initialize(path)
      super
      defaults
    end

    def defaults
      @component_path = build_path_for "components"
      @dialplan_path  = dup
      @log_path       = build_path_for "logs"
    end

    def base_path=(value)
      replace(value)
      defaults
    end

    def using_base_path(temporary_base_path, &block)
      original_path = dup
      self.base_path = temporary_base_path
      block.call
    ensure
      self.base_path = original_path
    end

    private
      def build_path_for(path)
        File.join(to_s, path)
      end
  end

  class Initializer

    class << self
      def get_rules_from(location)
        location = File.join location, ".ahnrc" if File.directory? location
        File.exists?(location) ? YAML.load_file(location) : nil
      end

      def ahn_root=(path)
        if Object.constants.map(&:to_sym).include?(:AHN_ROOT)
          Object.const_get(:AHN_ROOT).base_path = File.expand_path(path)
        else
          Object.const_set(:AHN_ROOT, PathString.new(File.expand_path(path)))
        end
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
      self.class.ahn_root = path
    end

    def start
      Adhearsion.status = :starting

      resolve_pid_file_path
      resolve_log_file_path
      daemonize! if should_daemonize?
      launch_console if need_console?
      switch_to_root_directory
      catch_termination_signal
      create_pid_file if pid_file
      bootstrap_rc
      initialize_log_file
      initialize_exception_logger
      load_all_init_files
      init_datasources
      init_components_subsystem
      init_modules
      init_events_subsystem
      load_components
      init_events_file

      ahn_log "Adhearsion v#{Adhearsion::VERSION::STRING} initialized!"
      Adhearsion.status = :running

      trigger_after_initialized_hooks
      join_important_threads

      self
    end

    def default_pid_path
      File.join AHN_ROOT, 'adhearsion.pid'
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
      @ahn_app_log_directory = AHN_ROOT + '/log'
      @log_file = File.expand_path(ahn_app_log_directory + "/adhearsion.log")
    end

    def switch_to_root_directory
      Dir.chdir AHN_ROOT
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
      rules = self.class.get_rules_from AHN_ROOT

      AHN_CONFIG.ahnrc = rules

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
      init_files_from_rc = AHN_CONFIG.files_from_setting("paths", "init").map { |file| File.expand_path(file) }
      already_loaded_init_files = Array(@loaded_init_files).map { |file| File.expand_path(file) }
      (init_files_from_rc - already_loaded_init_files).each { |init| load init }
    end

    def init_datasources
      require 'adhearsion/initializer/database.rb'
      require 'adhearsion/initializer/ldap.rb'

      DatabaseInitializer.start   if AHN_CONFIG.database_enabled?
      LdapInitializer.start       if AHN_CONFIG.ldap_enabled?
    end

    def init_modules

      require 'adhearsion/initializer/asterisk.rb'
      require 'adhearsion/initializer/drb.rb'
      require 'adhearsion/initializer/rails.rb'
      require 'adhearsion/initializer/xmpp.rb'
      # require 'adhearsion/initializer/freeswitch.rb'

      AsteriskInitializer.start   if AHN_CONFIG.asterisk_enabled?
      DrbInitializer.start        if AHN_CONFIG.drb_enabled?
      RailsInitializer.start      if AHN_CONFIG.rails_enabled?
      XMPPInitializer.start       if AHN_CONFIG.xmpp_enabled?
      # FreeswitchInitializer.start if AHN_CONFIG.freeswitch_enabled?

    end

    def init_events_subsystem
      application_events_files = AHN_CONFIG.files_from_setting("paths", "events")
      if application_events_files.any?
        Events.register_callback(:shutdown) do
          ahn_log.events "Performing a graceful stop of events subsystem"
          Events.framework_theatre.graceful_stop!
        end
        Events.framework_theatre.start!
      else
        ahn_log.events.warn 'No entries in the "events" section of .ahnrc. Skipping its initialization.'
      end
    end

    def init_events_file
      application_events_files = AHN_CONFIG.files_from_setting("paths", "events")
      application_events_files.each do |file|
        Events.framework_theatre.load_events_file file
      end
    end

    def should_daemonize?
      @mode == :daemon
    end

    def need_console?
      @mode == :console
    end

    def daemonize!
      ahn_log "Daemonizing now! Creating #{pid_file}."
      extend Adhearsion::CustomDaemonizer
      daemonize log_file
    end

    def launch_console
      require 'adhearsion/console'
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
      file_logger = Log4r::FileOutputter.new("Main Adhearsion log file", :filename => log_file, :trunc => false)

      if should_daemonize?
        Logging::AdhearsionLogger.outputters  = file_logger
      else
        Logging::AdhearsionLogger.outputters << file_logger
      end
      Logging::DefaultAdhearsionLogger.redefine_outputters
    end

    def initialize_exception_logger
      Events.register_callback :exception do |e|
        ahn_log.error "#{e.class}: #{e.message}"
        ahn_log.debug e.backtrace.join("\n\t")
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

    def init_components_subsystem
      @components_directory = File.expand_path "components"
      if File.directory? @components_directory
        Components.component_manager = Components::ComponentManager.new @components_directory
        Kernel.send(:const_set, :COMPONENTS, Components.component_manager.lazy_config_loader)
        Components.component_manager.globalize_global_scope!
        Components.component_manager.extend_object_with(Theatre::CallbackDefinitionLoader, :events)
      else
        ahn_log.warn "No components directory found. Not initializing any components."
      end
    end

    def load_components
      if Components.component_manager
        Components.component_manager.load_components
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
          ahn_log.error "Error after join()ing Thread #{Thread.inspect}. #{e.message}"
        ensure
          index = index + 1
        end
      end
    end

    class InitializationFailedError < StandardError; end
  end
end
