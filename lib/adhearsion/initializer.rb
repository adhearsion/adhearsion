module Adhearsion
  
  class PathString < String
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
    
    def dial_plan_named(name)
      File.join(dialplan_path, name)
    end
    
    private
      def build_path_for(path)
        File.join(to_s, path)
      end
  end
  
  class Initializer
    class << self
      def get_rules_from(location)
        if File.directory? location
          location = File.join location, ".ahnrc"
        end
        File.exists?(location) ? YAML.load_file(location) : nil
      end
      
      def ahn_root=(path)
        if Object.constants.include?("AHN_ROOT")
          Object.const_get(:AHN_ROOT).base_path = File.expand_path(path)
        else
          Object.const_set(:AHN_ROOT, PathString.new(File.expand_path(path)))
        end
      end
    end
  
    attr_reader :path, :daemon, :pid_file
    
    DEFAULT_RULES = { :pattern   => "*.rb",
                      :directory => "helpers"}
    
    # Creation of pid_files
    #
    #  - You may want to have Adhearsion create a process identification
    #    file when it boots so that a crash monitoring program such as
    #    Monit can reboot if necessary of so the init script can kill it
    #    for system shutdowns.
    #  - To have Adhearsion create a pid file in the default location (i.e.
    #    AHN_INSTALL_DIR/adhearsion.pid), supply :pid_file with 'true'. Otherwise
    #    one is not created UNLESS it is running in daemon mode, in which
    #    case one is created. You can force Adhearsion to not create one
    #    even in daemon mode by supplying "false".
    def initialize(path = nil, options = {})
      @path, @daemon, @pid_file = path, options[:daemon], options[:pid_file]
      
      self.class.ahn_root = path
      # See documentation for explanation of how :pid_file works. Have to
      # check for struct boolean equality because "true" means "use default".
      initialize_log_file
      resolve_pid_file
      switch_to_root_directory
      catch_termination_signal
      bootstrap_rc
      load_all_init_files
      init_modules
      daemonize! if running_in_daemon_mode?
      create_pid_file if pid_file
      load_components
      
      ahn_log "Adhearsion initialized!"
      
      trigger_after_initialized_hooks
    end
    
    def initialize_log_file
      ahn_app_log_directory = AHN_ROOT + '/log'
      Dir.mkdir(ahn_app_log_directory) unless File.directory? ahn_app_log_directory
      Adhearsion::Logging::DefaultAdhearsionLogger.outputters = [
        Adhearsion::Logging::DefaultAdhearsionOutputter,
        Log4r::FileOutputter.new("Main Adhearsion log file", :filename => ahn_app_log_directory + "/adhearsion.log", :trunc => false)
      ]
    end
    
    def create_pid_file(file = pid_file)
      if file
        File.open(pid_file, File::CREAT|File::WRONLY) do |file|
          file.write Process.pid
        end
        
        Hooks::TearDown.create_hook do
          File.delete(pid_file) if File.exists?(pid_file)
        end
      end
    end
    
    def init_modules
      require 'adhearsion/initializer/database.rb'
      require 'adhearsion/initializer/asterisk.rb'
      require 'adhearsion/initializer/drb.rb'
      require 'adhearsion/initializer/rails.rb'
      # require 'adhearsion/initializer/freeswitch.rb'
      
      DatabaseInitializer.start if AHN_CONFIG.database_enabled?
      AsteriskInitializer.start if AHN_CONFIG.asterisk_enabled?
      DrbInitializer.start      if AHN_CONFIG.drb_enabled?
      RailsInitializer.start    if AHN_CONFIG.rails_enabled?
      # FreeswitchInitializer.start if AHN_CONFIG.freeswitch_enabled?
    end
    
    def running_in_daemon_mode?
      ENV['DAEMON']
    end
    
    def resolve_pid_file
      @pid_file = if pid_file.is_a? TrueClass then default_pid_path
      elsif pid_file then pid_file
      elsif !pid_file.nil? && pid_file.is_a?(FalseClass) then nil
      # FIXME @pid_file = @daemon? Assignment or equality? I'm assuming equality.
      else @pid_file = @daemon ? default_pid_path : nil
      end
    end
    
    def switch_to_root_directory
      Dir.chdir AHN_ROOT
    end
    
    def catch_termination_signal
      Hooks::TearDown.catch_termination_signals
    end
    
    def load_all_init_files
      all_inits.each { |init| load init } if Paths.manager_for? "init"
    end
    
    def daemonize!
      puts "Daemonizing now! Creating #{pid_file}."
      fork
    end
    
    def load_components
      ComponentManager.load
      ComponentManager.start
    end
    
    def trigger_after_initialized_hooks
      Hooks::AfterInitialized.trigger_hooks
    end
    
    def bootstrap_rc
      rules = Initializer.get_rules_from(AHN_ROOT) || DEFAULT_RULES
      paths = rules['paths'] || DEFAULT_RULES
      paths.each_pair do |k,v|
        if v.kind_of? Hash
          directory, pattern = v['directory'] || '.', v['pattern'] || '*'
          Paths.manager_for k, :pattern => File.join(directory, pattern)
        else
          directory, pattern = '.', v
          Paths.manager_for k, :pattern => File.join(directory,pattern)
        end
      end
    end
    
    def fork(output = true)
      begin 
        require 'daemons'
      rescue
        raise InitializationFailedError, "To daemonize you must install the 'daemons' gem!"
      end
      
      # log_file = log_path("adhearsion") if Adhearsion::Paths.manager_for? "logs"
      Daemons.daemonize
    end
    
    def default_pid_path
      File.join AHN_ROOT, 'adhearsion.pid'
    end
    
    class InitializationFailedError < Exception; end
  end
end