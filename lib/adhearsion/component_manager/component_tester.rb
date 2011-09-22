module ComponentTester

  class << self

    ##
    #
    #
    # @return [Module] an anonymous module which includes the ComponentTester module.
    #
    def new(component_name, component_directory, main_file = nil)
      component_directory = File.expand_path component_directory
      main_file ||= "/#{component_name}/#{component_name}.rb"
      main_file.insert 0, component_directory

      component_manager = Adhearsion::Components::ComponentManager.new(component_directory)
      component_module  = Adhearsion::Components::ComponentManager::ComponentDefinitionContainer.load_file main_file

      Module.new do

        extend ComponentTester

        (class << self; self; end).send(:define_method, :component_manager)   { component_manager   }
        (class << self; self; end).send(:define_method, :component_name)      { component_name      }
        (class << self; self; end).send(:define_method, :component_module)    { component_module    }
        (class << self; self; end).send(:define_method, :component_directory) { component_directory }


        define_method(:component_manager)   { component_manager   }
        define_method(:component_name)      { component_name      }
        define_method(:component_module)    { component_module    }
        define_method(:component_directory) { component_directory }

        def self.const_missing(name)
          component_module.const_get name
        end

      end
    end
  end

  def helper_method(name)
    Object.new.extend(component_module).method(name)
  end

  def config
    component_manager.configuration_for_component_named component_name
  end

  def initialize!
    metadata = component_module.metaclass.send(:instance_variable_get, :@metadata)
    metadata[:initialization_block].call if metadata && metadata[:initialization_block].kind_of?(Proc)
  end

end
