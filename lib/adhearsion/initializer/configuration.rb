module Adhearsion
  class Configuration
    module ConfigurationEntryPoint
      def add_configuration_for(name)
        configuration_class_name = "#{name}Configuration"
        lowercased_name          = name.to_s.underscore

        class_eval(<<-EVAL, __FILE__, __LINE__)
          def enable_#{lowercased_name}(configuration_options = {})
            @#{lowercased_name}_configuration = #{configuration_class_name}.new(configuration_options)
          end

          def #{lowercased_name}
            @#{lowercased_name}_configuration
          end

          def #{lowercased_name}_enabled?
            !#{lowercased_name}.nil?
          end
        EVAL
      end
    end
    extend ConfigurationEntryPoint
    
    class << self
      def configure(&block)
        Adhearsion.module_eval { remove_const(:AHN_CONFIG) } if Adhearsion.const_defined?(:AHN_CONFIG)
        Adhearsion.const_set(:AHN_CONFIG, new(&block))
      end
    end
    
    attr_accessor :automatically_answer_incoming_calls
    attr_accessor :end_call_on_hangup
    attr_accessor :end_call_on_error
    
    def ahnrc
      @ahnrc
    end
    
    def ahnrc=(new_ahnrc)
      case new_ahnrc
        when Hash
          @raw_ahnrc = new_ahnrc.to_yaml.freeze
          @ahnrc = new_ahnrc.clone.freeze
        when String
          @raw_ahnrc = new_ahnrc.clone.freeze
          @ahnrc = YAML.load(new_ahnrc).freeze
      end
    end
    
    def logging(options)
      Adhearsion::Logging.logging_level = options[:level]
    end
    
    def files_from_setting(*path_through_config)
      queried_nested_setting = path_through_config.flatten.inject(@ahnrc) do |hash,key_name|
        if hash.kind_of?(Hash) && hash.has_key?(key_name)
          hash[key_name]
        else
          raise NameError, "Paths #{path_through_config.inspect} not found in .ahnrc!"
        end
      end
      raise NameError, "Paths #{path_through_config.inspect} not found in .ahnrc!" unless queried_nested_setting
      queried_nested_setting = Array queried_nested_setting
      queried_nested_setting.map { |filename| files_from_glob(filename) }.flatten.uniq
    end
    
    def initialize
      @automatically_answer_incoming_calls = true
      @end_call_on_hangup                  = true
      @end_call_on_error                   = true
      yield self if block_given?
    end
    
    private
    
    def files_from_glob(glob)
      Dir.glob "#{AHN_ROOT}/#{glob}"
    end
    
    class AbstractConfiguration
      extend ConfigurationEntryPoint
      
      class << self
        private
          def abstract_method!
            raise "Must be implemented in subclasses"
          end
      end
      
      def initialize(overrides = {})
        overrides.each_pair do |attribute, value|
          send("#{attribute}=", value)
        end
      end
    end
    
    # Abstract superclass for AsteriskConfiguration and FreeSwitchConfiguration.
    class TelephonyPlatformConfiguration < AbstractConfiguration
      attr_accessor :listening_port
      attr_accessor :listening_host
      
      class << self
        def default_listening_port
          abstract_method!
        end
        
        def default_listening_host
          '0.0.0.0'
        end
      end
        
      def initialize(overrides = {})
        @listening_port = self.class.default_listening_port
        @listening_host = self.class.default_listening_host
        super
      end
    end
    
    class AsteriskConfiguration < TelephonyPlatformConfiguration
      class << self
        attr_accessor :speech_engine
        
        def default_listening_port
          4573
        end
      end
      
      class AMIConfiguration < AbstractConfiguration
        attr_accessor :port, :username, :password, :events, :host
        
        class << self
          def default_port
            5038
          end

          def default_events
            false
          end
          
          def default_host
            'localhost'
          end
        end
        
        def initialize(overrides = {})
          self.host   = self.class.default_host
          self.port   = self.class.default_port
          self.events = self.class.default_events
          super
        end
      end
      add_configuration_for :AMI
    end
    add_configuration_for :Asterisk
    
    class FreeswitchConfiguration < TelephonyPlatformConfiguration
      class << self
        def default_listening_port
          4572
        end
      end
    end
    add_configuration_for :Freeswitch
    
    class DatabaseConfiguration < AbstractConfiguration
      attr_accessor :connection_options, :orm
      def initialize(options)
        @orm                = options.delete(:orm) || :active_record # TODO: ORM is a misnomer
        @connection_options = options
      end
    end
    add_configuration_for :Database
    
    class DrbConfiguration < AbstractConfiguration
      attr_accessor :port
      attr_accessor :host
      attr_accessor :acl

      # ACL = Access Control List

      class << self
        def default_port
          9050
        end
        
        def default_host
          'localhost'
        end
      end
      
      def initialize(overrides = {})
        self.port = overrides[:port] || self.class.default_port
        self.host = overrides[:host] || self.class.default_host
        self.acl  = overrides[:raw_acl]
        
        unless acl
          self.acl = []
          overrides[ :deny].to_a.each { |ip| acl << 'deny' << ip }
          overrides[:allow].to_a.each { |ip| acl << 'allow' << ip }
          acl.concat %w[allow 127.0.0.1] if acl.empty?
        end
      end
    end
    add_configuration_for :Drb
    
    class RailsConfiguration < AbstractConfiguration
      
      SUPPORTED_RAILS_ENVIRONMENTS = [:development, :test, :production]
      
      attr_accessor :rails_root, :environment
      def initialize(options)
        path_to_rails, environment = check_options options
        @rails_root = File.expand_path(path_to_rails)
        @environment = environment.to_sym
        raise ArgumentError, "Unrecognized environment type #@environment. Supported: " +
          SUPPORTED_RAILS_ENVIRONMENTS.to_sentence unless SUPPORTED_RAILS_ENVIRONMENTS.include?(@environment)
      end
    
      private
      
      def check_options(options)
        options = options.clone
        path    = options.delete :path
        env     = options.delete :env
        raise ArgumentError, "Unrecognied argument(s) #{options.keys.to_sentence} in Rails initializer!" unless options.size.zero?
        raise ArgumentError, "Must supply an :env argument to the Rails initializer!" unless env
        raise ArgumentError, "Must supply an :path argument to the Rails initializer!" unless path
        [path, env]
      end
    
    end
    add_configuration_for :Rails
    
  end
end
