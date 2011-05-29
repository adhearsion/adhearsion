require 'enumerator'
module Adhearsion
  module VoIP
    module Asterisk
      class ConfigurationManager

        class << self
          def normalize_configuration(file_contents)
            # cat sip.conf | sed -e 's/\s*;.*$//g' | sed -e '/^;.*$/d' | sed -e '/^\s*$/d'
            file_contents.split(/\n+/).map do |line|
              line.sub(/;.+$/, '').strip
            end.join("\n").squeeze("\n")
          end
        end

        attr_reader :filename

        def initialize(filename)
          @filename = filename
        end

        def sections
          @sections ||= read_configuration
        end

        def [](section_name)
          result = sections.find { |(name, *rest)| section_name == name }
          result.last if result
        end

        def delete_section(section_name)
          sections.reject! { |(name, *rest)| section_name == name }
        end

        def new_section(name, properties={})
          sections << [name, properties]
        end

        private

        def read_configuration
          normalized_file = self.class.normalize_configuration File.open(@filename, 'r'){|f| f.read}
          sections = normalized_file.split(/^\[([-_\w]+)\]$/)[1..-1]
          return [] if sections.nil?
          sections.each_slice(2).map do |(name,properties)|
            [name, hash_from_properties(properties)]
          end
        end

        def hash_from_properties(properties)
          properties.split(/\n+/).inject({}) do |property_hash,property|
            all, name, value = *property.match(/^\s*([^=]+?)\s*=\s*(.+)\s*$/)
            next property_hash unless name && value
            property_hash[name] = value
            property_hash
          end
        end
      end
    end
  end
end

# Read a file: cat a file
# Parse a file: separate into a two dimensional hash
