require 'fileutils'

module Adhearsion
  module CLI
    module AhnCommand
      USAGE = <<USAGE
Usage:
   ahn create /path/to/directory
   ahn start [daemon] [directory]
   ahn version|-v|--v|-version|--version
   ahn help|-h|--h|--help|-help

Under development:
   ahn install helpername
   ahn create:projectname /path/to/directory
   ahn search keyword
   ahn uninstall/remove helpername"
USAGE
    
      def self.execute!
        CommandHandler.send(*parse_arguments)
      end
      
      def self.parse_arguments(args=ARGV.clone)
        action = args.shift
        case action
          when /^-?-?h(elp)?$/        then [:help]
          when /^-?-?v(ersion)?$/     then [:version]
          when /^create(:([\w_.]+))?$/
            [:create, args.shift, $LAST_PAREN_MATCH || :default]
          when 'start'
            daemon, path = args
            path, daemon = daemon, path if !path || (path && daemon)
            [:start, path, daemon]
          when '-'
            [:start, Dir.pwd]
          else
            [action, *args]
        end
      end
      
      module CommandHandler
        class << self
          def create(path, project=:default)
            origin = AHN_INSTALL_DIR + "/applications/#{project}"
            raise UnknownProject, origin unless File.directory? origin
          
            FileUtils.makedirs path
            FileUtils.copy_entry origin, path
          
            # Seems so often Subversion files get thrown around.
            Dir.glob File.join(path, "**", '.svn') do |svndir|
              FileUtils.rm_rf svndir
            end
          
            # readme = File.read path + "/README.txt" rescue ""
            # puts "Adhearsion project generated!", "\n", readme
          end
        
          def start(path, daemon=false)
            raise PathInvalid, path unless File.exists? path + "/.ahnrc"
            Adhearsion::Initializer.new path, :daemon => daemon
          end
        
          def version
            puts "Adhearsion v#{Adhearsion::VERSION::STRING}"
          end
        
          def help
            puts USAGE
          end
        
          def method_missing(action, *args)
            raise UnknownCommand, [action, *args] * " "
          end
        end
        
        class UnknownCommand < Exception
          def initialize(cmd)
            super "Unknown command: #{cmd}\n#{USAGE}"
          end
        end
        
        class UnknownProject < Exception
          def initialize(project)
            super "Application #{project} does not exist! Have you installed it?"
          end
        end
        
        class PathInvalid < Exception
          def initialize(path)
            super "Directory #{path} does not contain an Adhearsion project!"
          end
        end
      end
    end
  end
end
