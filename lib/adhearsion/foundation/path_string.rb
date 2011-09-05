module Adhearsion
  class PathString < String

    class << self

      ##
      # Will return a PathString for the application root folder to which the specified arbitrarily nested subfolder belongs.
      # It works by traversing parent directories looking for the .ahnrc file. If no .ahnrc is found, nil is returned.
      #
      # @param [String] folder The path to the directory which should be a
      # @return [nil] if the subdirectory does not belong to a parent Adhearsion app directory
      # @return [PathString] if a directory is found
      #
      def from_application_subdirectory(folder)
        folder = File.expand_path folder
        ahn_rc = nil

        until ahn_rc || folder == "/"
          possible_ahn_rc = File.join(folder, ".ahnrc")
          if File.exists?(possible_ahn_rc)
            ahn_rc = possible_ahn_rc
          else
            folder = File.expand_path(folder + "/..")
          end
        end
        ahn_rc ? new(folder) : nil
      end
    end

    attr_accessor :component_path, :dialplan_path, :log_path

    def initialize(path)
      super
      defaults
    end

    def defaults
      @component_path = build_path_for "components"
      @dialplan_path  = dup
      @log_path       = build_path_for "logs"
    end

    def base_path=(value)
      replace(value)
      defaults
    end

    def using_base_path(temporary_base_path, &block)
      original_path = dup
      self.base_path = temporary_base_path
      block.call
    ensure
      self.base_path = original_path
    end

    private
      def build_path_for(path)
        File.join(to_s, path)
      end
  end
end
