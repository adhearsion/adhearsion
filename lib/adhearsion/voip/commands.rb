module Adhearsion
  module VoIP
    module Commands
      def self.for(platform_name)
        Adhearsion::VoIP.const_get(platform_name.to_s.classify).const_get("Commands")
      end
    end

    class PlaybackError < StandardError
      # Represents failure to play audio, such as when the sound file cannot be found
    end

    class RecordError < StandardError
      # Represents failure to record such as when a file cannot be written.
    end
  end
end
