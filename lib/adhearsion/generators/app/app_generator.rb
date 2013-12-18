# encoding: utf-8

module Adhearsion
  module Generators
    class AppGenerator < Generator

      BASEDIRS  = %w( config script spec )
      EMPTYDIRS = %w( lib spec/support spec/call_controllers )

      class_option :empty, type: :boolean

      def setup_project
        self.destination_root = @generator_name
        BASEDIRS.each { |dir| directory dir }
        EMPTYDIRS.each { |dir| empty_directory dir }

        template "Gemfile.erb", "Gemfile"
        template "adhearsion.erb", "config/adhearsion.rb"
        copy_file "gitignore", ".gitignore"
        copy_file "rspec", ".rspec"
        copy_file "Procfile"
        copy_file "Rakefile"
        copy_file "README.md"
        unless options[:empty]
          copy_file "simon_game.rb", "lib/simon_game.rb"
          copy_file "simon_game_spec.rb", "spec/call_controllers/simon_game_spec.rb"
        end
        chmod "script/ahn", 0755
      end
    end
  end
end
