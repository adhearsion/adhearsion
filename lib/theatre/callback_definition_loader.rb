module Theatre

  ##
  # This class provides the a wrapper aroung which an events.rb file can be instance_eval'd.
  #
  class CallbackDefinitionLoader

    attr_reader :theatre, :root_name
    def initialize(theatre, root_name=:events)
      @theatre   = theatre
      @root_name = root_name

      create_recorder_method root_name
    end

    def anonymous_recorder
      BlankSlateMessageRecorder.new(&method(:callback_registered))
    end

    ##
    # Parses the given Ruby source code file and returns this object.
    #
    # @param [String, File] file The filename or File object for the Ruby source code file to parse.
    #
    def load_events_file(file)
      file = File.open(file) if file.kind_of? String
      instance_eval file.read, file.path
      self
    end

    ##
    # Parses the given Ruby source code and returns this object.
    #
    # NOTE: Only use this if you're generating the code yourself! If you're loading a file from the filesystem, you should
    # use load_events_file() since load_events_file() will properly attribute errors in the code to the file from which the
    # code was loaded.
    #
    # @param [String] code The Ruby source code to parse
    #
    def load_events_code(code)
      instance_eval code
      self
    end

    protected

    ##
    # Immediately register the namespace and callback with the Theatre instance given to the constructor. This method is only
    # called when a new BlankSlateMessageRecorder is instantiated and receives #each().
    #
    def callback_registered(namespaces, callback)
      # Get rid of all arguments passed to the namespaces. Will support arguments in the future.
      namespaces = namespaces.map { |namespace| namespace.first }

      theatre.namespace_manager.register_callback_at_namespace namespaces, callback
    end

    def create_recorder_method(record_method_name)
      (class << self; self; end).send(:alias_method, record_method_name, :anonymous_recorder)
    end

    class BlankSlateMessageRecorder

      (instance_methods.map{|m| m.to_sym} - [:instance_eval, :object_id]).each { |method| undef_method method unless method.to_s =~ /^__/ }

      def initialize(&notify_on_completion)
        @notify_on_completion = notify_on_completion
        @namespaces = []
      end

      def method_missing(*method_name_and_args)
        raise ArgumentError, "Supplying a block is not supported" if block_given?
        @namespaces << method_name_and_args
        self
      end

      def each(&callback)
        @notify_on_completion.call(@namespaces, callback)
      end

    end

  end
end
