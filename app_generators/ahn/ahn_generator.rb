class AhnGenerator < RubiGen::Base

  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  default_options :author => nil

  attr_reader :name

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
    extract_options
  end

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      m.file  *[".ahnrc"]*2
      m.file  *["config/environment.rb"]*2
      m.file  *["config/adhearsion.rb"]*2
      m.file  *["dialplan.rb"]*2
      m.file  *["events.rb"]*2
      m.file  *["README"]*2
      m.file  *["Rakefile"]*2
      m.file  *["Gemfile"]*2
      m.file  *["lib/README.stomp_gateway.markdown"]*2
      m.file  *["lib/simon_game.rb"]*2
      m.file  *["lib/stomp_gateway.rb"]*2
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

    # Installation skeleton. Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      config
      lib
      script
    )
end
