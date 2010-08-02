require 'yaml'

module Adhearsion

  ##
  # This class isn't yet tied into Adhearsion.
  #
  class HostDefinition

    SUPPORTED_KEYS = [:host, :username, :password, :key, :name]

    cattr_reader :definitions
    @@definitions ||= []

    class << self
      def import_from_data_structure(local_definitions)
        case local_definitions
          when Array
            local_definitions.each do |definition|
              raise HostDefinitionException, "Unrecognized definition: #{definition}" unless definition.is_a?(Hash)
            end
            local_definitions.map { |definition| new definition }
          when Hash
            local_definitions.map do |(name,definition)|
              new definition.merge(:name => name)
            end
          else
            raise HostDefinitionException, "Unrecognized definition #{local_definitions}"
        end
      end

      def import_from_yaml(yaml_string)
        import_from_data_structure YAML.load(yaml_string)
      end

      def import_from_yaml_file(file)
        import_from_yaml YAML.load_file(file)
      end

      def clear_definitions!
        definitions.clear
      end
    end

    attr_reader :name, :host, :username, :password, :key
    def initialize(hash)
      @host, @username, @password, @key, @name = hash.values_at(*SUPPORTED_KEYS)
      @name ||= new_guid

      unrecognized_keys = hash.keys - SUPPORTED_KEYS
      raise HostDefinitionException, "Unrecognized key(s): #{unrecognized_keys.map(&:inspect).to_sentence}" if unrecognized_keys.any?
      raise HostDefinitionException, "You must supply a password or key!" if username && !(password || key)
      raise HostDefinitionException, "You must supply a username!" unless username
      raise HostDefinitionException, 'You cannot supply both a password and key!' if password && key
      raise HostDefinitionException, 'You must supply a host!' unless host

      self.class.definitions << self
    end

    class HostDefinitionException < StandardError

    end

  end


end