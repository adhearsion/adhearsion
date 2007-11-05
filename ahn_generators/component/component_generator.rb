class ComponentGenerator < RubiGen::Base
  
  default_options :author => nil
  
  attr_reader :name, :class_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
    @name       = @name.underscore
    @class_name = @name.camelize
    extract_options
  end

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory "components/#{name}/lib"
      m.directory "components/#{name}/test"

      # Create stubs
      m.file     "configuration.rb",    "components/#{name}/configuration.rb"
      m.template "lib/lib.rb.erb",      "components/#{name}/lib/#{name}.rb"
      m.template "test/test.rb.erb",    "components/#{name}/test/test_#{name}.rb"
      m.file     "test/test_helper.rb", "components/#{name}/test/test_helper.rb"
      
    end
  end

  protected
    def banner
      <<-EOS
Creates a ...

USAGE: #{$0} #{spec.name} name"
EOS
    end

    def add_options!(opts)
      # opts.separator ''
      # opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |options[:author]| }
      # opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end
    
    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end
end