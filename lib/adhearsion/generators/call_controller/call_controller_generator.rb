begin
  require 'thor/group'
rescue LoadError
  puts "Thor is not available.\nIf you ran this command from a git checkout " \
       "of Adhearsion, please make sure thor is installed,\nand run this command " \
       "as `ruby #{$0} #{(ARGV | ['--dev']).join(" ")}`"
  exit
end

module Adhearsion
  module Generators
    class CallControllerGenerator < Thor::Group
      include Thor::Actions

      argument :controller_name, :type => :string

      def self.source_root(path = nil)
        path = File.join(base_root, 'templates')
        path if File.exists?(path)
      end

      def self.base_root
        File.dirname(__FILE__)
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
