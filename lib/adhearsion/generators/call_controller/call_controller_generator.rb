module Adhearsion
  module Generators
    class CallControllerGenerator < Generator
      argument :controller_name, :type => :string

      def self.source_root(path = nil)
        path = File.join(base_root, 'call_controller', 'templates')
        path if File.exists?(path)
      end

      def create_controller
        raise Exception, "Generator commands need to be run in an Adhearsion app directory" unless ScriptAhnLoader.in_ahn_application?('.')
        self.destination_root = '.'
        empty_directory('lib')
        empty_directory('spec')
        template('lib/controller.erb',"lib/#{@controller_name.underscore}.rb")
        template('spec/controller_spec.erb',"spec/#{@controller_name.underscore}_spec.rb")
      end

    end
  end
end
