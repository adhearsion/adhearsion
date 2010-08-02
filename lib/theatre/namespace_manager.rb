module Theatre

  ##
  # Manages the hierarchial namespaces of a Theatre. This class is Thread-safe.
  #
  class ActorNamespaceManager

    VALID_NAMESPACE = %r{^(/[\w_]+)+$}

    class << self
      def valid_namespace_path?(namespace_path)
        namespace_path =~ VALID_NAMESPACE
      end

      ##
      # Since there are a couple ways to represent namespaces, this is a helper method which will normalize
      # them into the most practical: an Array of Symbols
      # @param [String, Array] paths The namespace to register. Can be in "/foo/bar" or *[foo,bar] format
      def normalize_path_to_array(paths)
        paths = paths.is_a?(Array) ? paths.flatten : Array(paths)
        paths.map! { |path_segment| path_segment.kind_of?(String) ? path_segment.split('/') : path_segment }
        paths.flatten!
        paths.reject! { |path| path.nil? || (path.kind_of?(String) && path.empty?) }
        paths.map { |path| path.to_sym }
      end

    end

    def initialize
      @registry_lock = Mutex.new
      @root          = RootNamespaceNode.new
    end

    ##
    # Have this registry recognize a new path and prepare it for callback registrations. All path segements will be created
    # in order. For example, when registering "/foo/bar/qaz" when no namespaces at all have been registered, this method will
    # first register "foo", then "bar", then "qaz". If the namespace was already registered, it will not be affected.
    #
    # @param [String, Array] paths The namespace to register. Can be in "/foo/bar" or *[foo,bar] format
    # @return [NamespaceNode] The NamespaceNode representing the path given.
    # @raise NamespaceNotFound if a segment has not been registered yet
    #
    def register_namespace_name(*paths)
      paths = self.class.normalize_path_to_array paths

      paths.inject(@root) do |node, name|
        node.register_namespace_name name
      end
    end

    ##
    # Returns a Proc found after searching with the namespace you provide
    #
    # @raise NamespaceNotFound if a segment has not been registered yet
    #
    def callbacks_for_namespaces(*paths)
      search_for_namespace(paths).callbacks
    end

    ##
    # Find a namespace in the tree.
    #
    # @param [Array, String] paths Must be an Array of segments or a name like "/foo/bar/qaz"
    # @raise NamespaceNotFound if a segment has not been registered yet
    #
    def search_for_namespace(paths)
      paths = self.class.normalize_path_to_array paths
      path_string = "/"

      found_namespace = paths.inject(@root) do |last_node,this_node_name|
        raise NamespaceNotFound.new(path_string) if last_node.nil?
        path_string << this_node_name.to_s
        last_node.child_named this_node_name
      end
      raise NamespaceNotFound.new("/#{paths.join('/')}") unless found_namespace
      found_namespace
    end

    ##
    # Registers the given callback at a namespace, assuming the namespace was already registered.
    #
    # @param [Array] paths Must be an Array of segments
    # @param [Proc] callback
    # @raise NamespaceNotFound if a segment has not been registered yet
    #
    def register_callback_at_namespace(paths, callback)
      raise ArgumentError, "callback must be a Proc" unless callback.kind_of? Proc
      search_for_namespace(paths).register_callback callback
    end

    protected

    ##
    # Used by NamespaceManager to build a tree of namespaces. Has a Hash of children which is not
    # Thread-safe. For Thread-safety, all access should semaphore through the NamespaceManager.
    class NamespaceNode

      attr_reader :name
      def initialize(name)
        @name = name.freeze
        @children  = {}
        @callbacks = []
      end

      def register_namespace_name(name)
        @children[name] ||= NamespaceNode.new(name)
      end

      def register_callback(callback)
        @callbacks << callback
        callback
      end

      def callbacks
        @callbacks.clone
      end

      def delete_callback(callback)
        @callbacks.delete callback
      end

      def child_named(name)
        @children[name]
      end

      def destroy_namespace(name)
        @children.delete name
      end

      def root?
        false
      end

    end

    class RootNamespaceNode < NamespaceNode
      def initialize
        super :ROOT
      end
      def root?
        true
      end
    end

  end

  class NamespaceNotFound < StandardError
    def initialize(full_path)
      super "Could not find #{full_path.inspect} in the namespace registry. Did you register it yet?"
    end
  end

end
