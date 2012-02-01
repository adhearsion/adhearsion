module Adhearsion
  module Generators
    class AppGenerator < Generator

      BASEDIRS = %w( config lib script )

      def self.source_root(path = nil)
        path = File.join(base_root, 'app', 'templates')
        path if File.exists?(path)
      end

      argument :app_action, :type => :string
      argument :app_path,   :type => :string

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
