module Adhearsion
  module Generators
    class AppGenerator < Generator

      BASEDIRS = %w( config lib script )

      def self.source_root(path = nil)
        path = File.join(base_root, 'app', 'templates')
        path if File.exists?(path)
      end

      def setup_project
        self.destination_root = @generator_name
        BASEDIRS.each { |dir| directory dir }
        template "Gemfile.erb", "Gemfile"
        copy_file "gitignore", ".gitignore"
        copy_file "Procfile"
        copy_file "Rakefile"
        copy_file "README.md"
        chmod "script/ahn", 0755
      end
    end
  end
end
