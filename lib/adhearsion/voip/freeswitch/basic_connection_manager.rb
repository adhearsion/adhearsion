module Adhearsion
  module VoIP
    module FreeSwitch

      class BasicConnectionManager

        def initialize(io)
          @io = io
        end

        # The send-command operator
        def <<(str)
          @io.write str + "\n\n"
        end

        def get_header
          separate_pairs get_raw_header
        end

        def get_raw_header
          ([].tap do |lines|
            until line = @io.gets and line.chomp.empty?
              lines << line.chomp
            end
          end) * "\n"
        end

        def next_event
          header = get_raw_header
          length = header.first[/\d+$/].to_i
          # puts "Reading an event of #{length} bytes"
          separate_pairs @io.read(length)
        end

        def separate_pairs(lines)
          lines.split("\n").inject({}) do |h,line|
            h.tap do |hash|
              k,v = line.split(/\s*:\s*/)
              hash[k] = URI.unescape(v).strip if k && v
            end
          end
        end

      end

    end
  end
end
