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
    class ConfigurationBase < OpenStruct
      def [](name)
        self.send(name)
      end
      def []=(name, value)
        self.send(name.to_s.concat("=").to_sym, value)
      end
    end


    class Configuration < ConfigurationBase
      def length
        self.methods(false).length / 2 # setter and getter
      end
    end
  end
end
