# encoding: utf-8

require 'adhearsion/application'
require 'adhearsion/linux_proc_name'
require 'adhearsion/rayo/initializer'
require 'adhearsion/http_server'
require 'rbconfig'

module Adhearsion
  class Initializer

    class << self
      def start(*args, &block)
        new(*args, &block).start
      end
    end

    attr_reader :path

    def initialize(options = {})
      @@started = true
      @path     = path
      @console  = options[:console]
      @loaded_init_files  = options[:loaded_init_files]
      Adhearsion.root = '.'
    end

    def start
      catch :boot_aborted do
        configure_plugins
        load_lib_folder
        load_app_file
        load_config_file
        load_events_file
        load_routes_file

        Adhearsion.statistics
        start_logging
        debugging_log
        launch_console if need_console?
        catch_termination_signal
        set_ahn_proc_name
        initialize_exception_logger
        setup_i18n_load_path
        Rayo::Initializer.init
        HTTPServer.start
        init_plugins

        Rayo::Initializer.run
        run_plugins
        trigger_after_initialized_hooks

        Adhearsion::Process.booted if Adhearsion.status == :booting

        logger.info "Adhearsion v#{Adhearsion::VERSION} initialized in \"#{Adhearsion.environment}\"!" if Adhearsion.status == :running
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

    def setup_i18n_load_path
      Adhearsion.config.core.i18n.locale_path.each do |dir|
        logger.debug "Adding #{dir} to the I18n load path"
        ::I18n.load_path += Dir["#{dir}/**/*.yml"]
      end
    end

    def catch_termination_signal
      self_read, self_write = IO.pipe

      %w(INT TERM HUP ALRM ABRT USR2).each do |sig|
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
      when 'ALRM'
        logger.info "Received SIGALRM. Toggling trace logging."
        Adhearsion::Logging.toggle_trace!
      when 'ABRT'
        logger.info "Received ABRT signal. Forcing stop."
        Adhearsion::Process.force_stop
      when 'USR2'
        logger.info "Received USR2 signal. Printing Celluloid stack dump."
        Celluloid.stack_dump(STDOUT)
      end
    end

    ##
    # Loads files in application lib folder
    # @return [Boolean] if files have been loaded (lib folder is configured to not nil and actually exists)
    def load_lib_folder
      return false if Adhearsion.config.core.lib.nil?

      lib_folder = [Adhearsion.config.core.root, Adhearsion.config.core.lib].join '/'
      return false unless File.directory? lib_folder

      $LOAD_PATH.unshift lib_folder

      Dir.chdir lib_folder do
        rbfiles = File.join "**", "*.rb"
        Dir.glob(rbfiles).each do |file|
          require "#{lib_folder}/#{file}"
        end
      end
      true
    end

    def load_app_file
      path = "#{Adhearsion.config.root}/config/app.rb"
      load path if File.exist?(path)
    end

    def load_config_file
      load "#{Adhearsion.config.root}/config/adhearsion.rb"
    end

    def load_events_file
      Adhearsion::Events.init
      path = "#{Adhearsion.config.root}/config/events.rb"
      load path if File.exist?(path)
    end

    def load_routes_file
      path = "#{Adhearsion.config.root}/config/routes.rb"
      load path if File.exist?(path)
    end

    def configure_plugins
      Plugin.configure_plugins
    end

    def init_plugins
      Plugin.init_plugins
    end

    def run_plugins
      Plugin.run_plugins
    end

    def need_console?
      @console == true
    end

    def launch_console
      Thread.new do
        catching_standard_errors do
          Adhearsion::Console.run
        end
      end
    end

    def start_logging
      Adhearsion::Logging.start Adhearsion.config.core.logging.level, Adhearsion.config.core.logging.formatter
    end

    def initialize_exception_logger
      Events.register_handler :exception do |e, l|
        (l || logger).error e
      end
    end

    def set_ahn_proc_name
      Adhearsion::LinuxProcName.set_proc_name Adhearsion.config.core.process_name
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
