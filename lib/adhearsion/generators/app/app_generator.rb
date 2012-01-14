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
    class AppGenerator < Thor::Group
      include Thor::Actions

      BASEDIRS = %w( config lib script )

      argument :app_action,               :type => :string
      argument :app_path,               :type => :string

      def self.source_root(path=nil)
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
        copy_file "README"
      end
    end
  end
end
