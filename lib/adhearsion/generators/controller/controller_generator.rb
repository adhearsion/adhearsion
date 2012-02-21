module Adhearsion
  module Generators
    class ControllerGenerator < Generator

      argument :controller_name, :type => :string

      def create_controller
        raise Exception, "Generator commands need to be run in an Adhearsion app directory" unless ScriptAhnLoader.in_ahn_application?('.')
        self.destination_root = '.'
        empty_directory 'lib'
        empty_directory 'spec'
        template 'lib/controller.rb', "lib/#{@controller_name.underscore}.rb"
        template 'spec/controller_spec.rb', "spec/#{@controller_name.underscore}_spec.rb"
      end

    end
  end
end
