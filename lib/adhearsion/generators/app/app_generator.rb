# encoding: utf-8

module Adhearsion
  module Generators
    class AppGenerator < Generator

      BASEDIRS  = %w( config script spec )
      EMPTYDIRS = %w( app/assets/audio/en app/call_controllers config/locales lib spec/support spec/call_controllers )

      class_option :empty, type: :boolean

      def setup_project
        self.destination_root = @generator_name
        BASEDIRS.each { |dir| directory dir }
        EMPTYDIRS.each { |dir| empty_directory dir }

        template "Gemfile.erb", "Gemfile"
        template "adhearsion.erb", "config/adhearsion.rb"
        template "events.erb", "config/events.rb"
        template "routes.erb", "config/routes.rb"
        copy_file "gitignore", ".gitignore"
        copy_file "rspec", ".rspec"
        copy_file "Procfile"
        copy_file "Rakefile"
        copy_file "README.md"
        unless options[:empty]
          copy_file "hello_world.wav", "app/assets/audio/en/hello_world.wav"
          copy_file "simon_game.rb", "app/call_controllers/simon_game.rb"
          copy_file "en.yml", "config/locales/en.yml"
          copy_file "simon_game_spec.rb", "spec/call_controllers/simon_game_spec.rb"
        end
        chmod "script/ahn", 0755
      end
    end
  end
end
