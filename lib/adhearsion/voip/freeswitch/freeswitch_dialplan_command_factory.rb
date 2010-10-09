require 'adhearsion/voip/dsl/dialplan/dispatcher'

module Adhearsion
  module VoIP
    module FreeSwitch
      class FreeSwitchDialplanCommandFactory

        def initialize(context=nil)
          @context = context
        end

        # These should all return those objects...
        def speak(text, hash={})
          voice, engine = hash[:voice] || "Dianne", hash[:engine] || "cepstral"

          dtmf = hash[:on_keypress]
          speak_cmd = cmd 'speak', "#{engine}|#{voice}|%p" % text, :on_keypress => dtmf

          if hash[:timeout] == 0
            [speak_cmd, DSL::Dialplan::NoOpEventCommand.new(hash[:timeout], :on_keypress => dtmf)]
          else
            puts "Returning the normal speak command"
            speak_cmd
          end
        end

        def set(key, value)
          cmd 'set', "#{key}=#{value}"
        end

        def play(*files)
          hash = files.last.kind_of?(Hash) ? files.pop : {}
          conference, to = hash[:conference], hash[:to]
          puts "conference: #{conference.inspect}, to: #{to.inspect}, hash: #{hash.inspect}, files: #{files.inspect}"
          if conference
            # Normal (inbound) event socket playing to a conference
            files.map do |file|
              cmd "conference", "#{conference} play #{file} #{to}"
            end
          elsif to
            # Normal event socket syntax
            files.map do |file|
              # TODO: Support playing to an individual leg of the call.
              cmd "broadcast", "#{to} #{file} both"
            end
          else
            # Outbound event sockets
            files.map { |file| cmd('playback', file) }
          end
        end

        def join(id)
          DSL::Dialplan::ExitingEventCommand.new "conference", id.to_s
        end

        def hangup!
          cmd "exit"
        end

        def return!(obj)
          raise DSL::Dialplan::ReturnValue.new(obj)
        end

        def hangup!
          raise DSL::Dialplan::Hangup
        end

        def wait(seconds=nil, &block)
          DSL::Dialplan::NoOpEventCommand.new(seconds)
        end

        def record(hash={}, &block)
          # TODO: Could want to record a conference or a UUID
          p hash
          if hash[:stop]
            cmd 'stop_record_session', hash[:stop]
          else
            file = hash[:file] || File.join(Dir::tmpdir, String.random(32), '.wav')

            raise "Cannot supply both a timeout and a block!" if hash[:timeout] && block_given?

            dtmf_breaker = lambda do |digit|
              return! file if digit == hash[:break_on]
            end

            rec_cmd = cmd "record", file, :on_keypress => dtmf_breaker
            [].tap do |cmds|
              cmds << play('beep') if hash[:beep]
              cmds << rec_cmd
              if hash[:timeout]
                cmds << DSL::Dialplan::NoOpEventCommand.new(hash[:timeout])
              elsif block_given?
                cmds << block
                cmds << record(:stop => file)
              end
              cmds << file
              p cmds
              cmds
            end
          end
        end

        def input(number=nil, hash={})
          timeout, file = hash[:timeout], hash[:play] || hash[:file]
          break_on = hash[:break_on] || '#'

          # TODO: compile play() and set its DTMF callback to this one
          digits = []
          dtmf_hook = lambda do |digit|
            puts "RECEIVED #{digit} WITH #{digits}"
            return! digits.to_s if digit.to_s == break_on.to_s
            digits << digit
            return! digits.to_s if number && digits.size >= number
          end
          DSL::Dialplan::NoOpEventCommand.new.tap do |command|
            command.on_keypress &dtmf_hook
          end
        end

        private

        def cmd(*args, &block)
          DSL::Dialplan::EventCommand.new(*args, &block)
        end

      end
    end
  end
end