class AhnGenerator < RubiGen::Base

  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  default_options :author => nil

  attr_reader :name, :component

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
    @component = 'simon_game'
    extract_options
  end

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      m.file  *[".ahnrc"]*2

      m.file  *["components/simon_game/simon_game.rb"]*2
      m.file  *["components/ami_remote/ami_remote.rb"]*2

      m.file  *["components/disabled/xmpp_gateway/xmpp_gateway.rb"]*2
      m.file  *["components/disabled/xmpp_gateway/xmpp_gateway.yml"]*2
      m.file  *["components/disabled/xmpp_gateway/README.markdown"]*2

      m.file  *["components/disabled/stomp_gateway/stomp_gateway.rb"]*2
      m.file  *["components/disabled/stomp_gateway/stomp_gateway.yml"]*2
      m.file  *["components/disabled/stomp_gateway/README.markdown"]*2

      m.file  *["config/environment.rb"]*2
      m.file  *["config/startup.rb"]*2
      m.file  *["dialplan.rb"]*2
      m.file  *["events.rb"]*2
      m.file  *["README"]*2
      m.file  *["Rakefile"]*2
      m.file  *["Gemfile"]*2
      m.file  *["script/ahn"]*2

      # m.dependency "install_rubigen_scripts", [destination_root, 'ahn', 'adhearsion', 'test_spec'],
      #   :shebang => options[:shebang], :collision => :force
    end
  end

  protected
    def banner
      <<-EOS
Creates a ...

USAGE: #{spec.name} name"
EOS
    end

    def add_options!(opts)
      opts.separator ''
      opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |options[:author]| }
      opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end

    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      components/simon_game
      components/disabled/stomp_gateway
      components/disabled/xmpp_gateway
      components/ami_remote
      config
      script
    )
end
