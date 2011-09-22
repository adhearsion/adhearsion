module Adhearsion
  module Asterisk
    module Commands
      module SpeechEngines
        class InvalidSpeechEngine < StandardError; end

        class << self
          def cepstral(call, text, options = {})
            # We need to aggressively escape commas so app_swift does not
            # think they are arguments.
            text.gsub! /,/, '\\\\\\,'
            command = ['Swift', text]

            if options[:interrupt_digits]
              ahn_log.agi.warn 'Cepstral does not support specifying interrupt digits'
              options[:interruptible] = true
            end
            # Wait for 1ms after speaking and collect no more than 1 digit
            command += [1, 1] if options[:interruptible]
            call.execute *command
            call.get_variable('SWIFT_DTMF')
          end

          def unimrcp(call, text, options = {})
            # app_unimrcp strips quotes, which will already be stripped by the AGI parser.
            # To work around this bug, we have to actually quote the arguments twice, once
            # in this method and again inside #execute.
            # Example from the logs:
            # AGI Input: EXEC MRCPSynth "<speak xmlns=\"http://www.w3.org/2001/10/synthesis\" version=\"1.0\" xml:lang=\"en-US\"> <voice name=\"Paul\"> <prosody rate=\"1.0\">Howdy, stranger. How are you today?</prosody> </voice> </speak>"
            # [Aug  3 13:39:02] VERBOSE[8495] logger.c:     -- AGI Script Executing Application: (MRCPSynth) Options: (<speak xmlns="http://www.w3.org/2001/10/synthesis" version="1.0" xml:lang="en-US"> <voice name="Paul"> <prosody rate="1.0">Howdy, stranger. How are you today?</prosody> </voice> </speak>)
            # [Aug  3 13:39:02] NOTICE[8495] app_unimrcp.c: Text to synthesize is: <speak xmlns=http://www.w3.org/2001/10/synthesis version=1.0 xml:lang=en-US> <voice name=Paul> <prosody rate=1.0>Howdy, stranger. How are you today?</prosody> </voice> </speak>
            command = ['MRCPSynth', text.gsub(/["\\]/) { |m| "\\#{m}" }]
            args = []
            if options[:interrupt_digits]
              args << "i=#{options[:interrupt_digits]}"
            else
              args << "i=any" if options[:interruptible]
            end
            command << args.join('&') unless args.empty?
            value = call.inline_return_value(call.execute *command)
            value.to_i.chr unless value.nil?
          end

          def tropo(call, text, options = {})
            command = ['Ask', text]
            args = {}
            args[:terminator] = options[:interrupt_digits].split('').join(',') if options[:interrupt_digits]
            args[:bargein] = options[:interruptible] if options.has_key?(:interruptible)
            command << args.to_json unless args.empty?
            value = JSON.parse call.raw_response(*command).sub(/^200 result=/, '')
            value['interpretation']
          end

          def festival(text, call, options = {})
            raise NotImplementedError
          end

          def none(text, call, options = {})
            raise InvalidSpeechEngine, "No speech engine selected. You must specify one in your Adhearsion config file."
          end

          def method_missing(engine_name, text, options = {})
            raise InvalidSpeechEngine, "Unsupported speech engine #{engine_name} for speaking '#{text}'"
          end
        end
      end
    end
  end
end
