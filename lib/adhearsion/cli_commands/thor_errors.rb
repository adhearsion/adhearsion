# encoding: utf-8

module Adhearsion
  module CLI
    class UnknownCommand < Thor::Error
      def initialize(cmd)
        super "Unknown command: #{cmd}"
      end
    end

    class PathRequired < Thor::Error
      def initialize(cmd)
        super "A valid path is required for #{cmd}, unless run from an Adhearson app directory"
      end
    end

     class UnknownGeneratorError < Thor::Error
      def initialize(gentype)
        puts "Please specify generator to use (#{Adhearsion::Generators.mappings.keys.join(", ")})"
        super "Unknown command: #{gentype}"
      end
    end

    class PathInvalid < Thor::Error
      def initialize(path)
        super "Directory #{path} does not belong to an Adhearsion project!"
      end
    end

    class PIDReadError < Thor::Error
      def initialize(path)
        super "Could not read pid from the file #{path}"
      end
    end
  end
end
