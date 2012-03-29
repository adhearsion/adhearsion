# encoding: utf-8

module Adhearsion
  module Generators
    class AppGenerator < Generator

      BASEDIRS = %w( config lib script spec )
      EMPTYDIRS = %w( spec/call_controllers spec/support )

      def setup_project
        self.destination_root = @generator_name
        BASEDIRS.each { |dir| directory dir }
        EMPTYDIRS.each { |dir| empty_directory dir }
        template "Gemfile.erb", "Gemfile"
        copy_file "gitignore", ".gitignore"
        copy_file "rspec", ".rspec"
        copy_file "Procfile"
        copy_file "Rakefile"
        copy_file "README.md"
        chmod "script/ahn", 0755
      end
    end
  end
end
