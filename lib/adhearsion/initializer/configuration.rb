module Adhearsion
  class Configuration
    module ConfigurationEntryPoint
      def add_configuration_for(name)
        lowercased_name          = name.to_s.underscore
        configuration_class_name = "#{name}Configuration"

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
    
    def initialize
      @automatically_answer_incoming_calls = true
      @end_call_on_hangup                  = true
      @end_call_on_error                   = true
      yield self if block_given?
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

      class << self
        def default_port
          9050
        end
        
        def default_host
          'localhost'
        end
      end
      
      def initialize(overrides = {})
        self.port = overrides.delete(:port) || self.class.default_port
        self.host = overrides.delete(:host) || self.class.default_host
        self.acl  = overrides.delete(:raw_acl)
        if not self.acl
          self.acl = []
          denies = overrides.delete(:deny)
          denies.each do |ip|
            self.acl << "deny" << ip
          end if denies
          allows = overrides.delete(:allow)
          allows.each do |ip|
            self.acl << "allow" << ip
          end if allows
          self.acl << "allow" << "all" if self.acl.blank?
        end
      end
    end
    add_configuration_for :Drb
  end
end
