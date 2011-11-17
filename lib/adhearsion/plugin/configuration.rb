module Adhearsion
  class Plugin

    # This class inherits from OpenStruct to allow any configuration key,
    # either using methods or Hash format
    #
    # config = ConfigurationBase.new
    # config[:foo] = "bar"
    # puts config.foo => "bar"
    # config.bar = "foo"
    # puts config[:bar] => "foo"
    #

    class Configuration < Adhearsion::BasicConfiguration
      
      def length
        values.length
      end

      def method_missing(method_name, *args)
        config_name = method_name
        values = case args.length
          when 0
            [nil, ""]
          when 1
            [args[0], ""]
          when 2
            [args[0], args[1]]
          else
            [args[0], args[1]]
          end  
        self.values << Definition.new(config_name, values[0], values[1])
        self.values
      end      

      def values
        @values ||= []
      end

    end

    class Definition
      attr_accessor :name
      attr_accessor :value
      attr_accessor :default_value
      attr_accessor :description

      def initialize name, default_value, description
        @name = name
        @default_value = default_value
        @description = description
        @value = nil
      end

      def to_s
        "Config param <#{name}>: #{description} (default value <#{default_value.to_s}>)"
      end
    end
  end
end
