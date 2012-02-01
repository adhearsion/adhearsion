module Adhearsion
  module Generators
    class AppGenerator < Generator

      BASEDIRS = %w( config lib script )

      argument :app_action, :type => :string
      argument :app_path,   :type => :string

      def self.source_root(path = nil)
        path = File.join(base_root, 'templates')
        path if File.exists?(path)
      end

      def self.base_root
        File.dirname(__FILE__)
      end

      def setup_project
        self.destination_root = @app_path
        BASEDIRS.each { |dir| directory dir }
        copy_file "Gemfile"
        copy_file "Rakefile"
        copy_file "README.md"
      end
    end
  end
end
