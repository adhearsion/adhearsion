module Adhearsion
  module VoIP
    module Asterisk
      module Commands
        TONES = {
          :busy   => "480+620/500,0/500",
          :dial   => "440+480/2000,0/4000",
          :info   => "!950/330,!1400/330,!1800/330,0",
          :record => "1400/500,0/15000"
        } unless defined? TONES
        
        RESPONSE_PREFIX = "200 result=" unless defined? RESPONSE_PREFIX
        DIAL_STATUSES   = Hash.new(:unknown).merge(:answer      => :answered,
                                                   :congestion  => :congested, 
                                                   :busy        => :busy,
                                                   :cancel      => :cancelled,
                                                   :noanswer    => :unanswered,
                                                   :chanunavail => :channel_unavailable) unless defined? DIAL_STATUSES
        def write(message)
          to_pbx.print(message)
        end
        
        def read
          from_pbx.gets
        end
        
        def raw_response(message = nil)
          write message if message
          read
        end
        
        def execute(application, *arguments)
          result = raw_response("EXEC #{application} #{arguments * '|'}")
          return false if error?(result)
          result
        end
        
        def hangup
          raw_response 'HANGUP'
        end
        
        def play(*arguments)
          arguments.flatten.each do |argument|
            play_time(argument) || play_numeric(argument) || play_string(argument)
          end
        end
        
        # Plays a tone over the call.
        #
        # Usage:
        #  - tone:busy
        #  - tone:dial
        #  - tone:info
        #  - tone:record
        #  - tone "3333/33,0/15000" # Random custom tone
        #
        # (http://www.voip-info.org/wiki/index.php?page=Asterisk+cmd+Playtones)
        def tone(type_name_or_raw_tone)
          tone_code = TONES[type_name_or_raw_tone] || type_name_or_raw_tone
          execute 'PlayTones', tone_code
        end
          
        # Input is used to receive keypad input from the user, pausing until they
      	# have entered the desired number of digits (specified with the first
      	# parameter) or the timeout has been reached (specified as a hash argument
      	# with the key :timeout). By default, there is no timeout, waiting infinitely.
      	#
      	# If you desire a sound to be played other than a simple beep to instruct
      	# the callee to input data, pass the filename as an hash argument with either
      	# the :play or :file key.
      	#
      	# When called without any arguments (or a first argument of -1), the user is
      	# able to enter digits ad infinitum until they press the pound (#) key.
      	#
      	# Note: input() does NOT catch "#" character! Use wait_for_digit instead.
        def input(digits = nil, options = {})
          timeout = options[:timeout]
          timeout = (timeout && timeout != -1) ? (timeout * 1000).to_i : -1
          play    = options[:play] || 'beep'
      	  result  = raw_response("GET DATA #{play} #{timeout} #{digits}") 
      	  extract_input_from result
      	end
      	
      	# Returns the status of the last dial(). Possible dial
        # statuses include :answer, :busy, :no_answer, :cancelled,
        # :congested, and :channel_unavailable. If :cancel is
      	# returned, the caller hung up before the callee picked
      	# up. If :congestion is returned, the dialed extension
      	# probably doesn't exist. If :channel_unavailable, the callee
      	# phone may not be registered.
      	def last_dial_status
      	  DIAL_STATUSES[get_dial_status]
      	end

        def last_dial_successful?
          last_dial_status == 'ANSWER'
        end

        def last_dial_unsuccessful?
          not last_dial_successful?
        end
        
        def speak(text, engine=:none)
          engine = Adhearsion::Configuration::AsteriskConfiguration.speech_engine || engine
          execute SpeechEngines.send(engine, text)
        end
        
        # Used to join a particular conference with the MeetMe application. To
        # use MeetMe, be sure you have a proper timing device configured on your
        # Asterisk box. MeetMe is Asterisk's built-in conferencing program.
        # More info: http://www.voip-info.org/wiki-Asterisk+cmd+MeetMe
        def join(conference_id, options={})
          conference_id = conference_id.to_s.scan(/\w/).join
          command_flags = options[:options].to_s # This is a passthrough string straight to Asterisk
          pin = options[:pin]
          raise ArgumentError, "A conference PIN number must be numerical!" if pin && pin.to_s !~ /^\d+$/
          # The 'd' option of MeetMe creates conferences dynamically.
          command_flags += 'd' unless command_flags.include? 'd'
          
          execute "MeetMe", conference_id, command_flags, options[:pin]
        end
        
        def record
          # TODO
          puts "RECORD NOT IMPLEMENTED."
          String.random # Simulates the returned filename
        end
        
      	def get_variable(variable_name)
      	  result = raw_response("GET VARIABLE #{variable_name}")
      	  extract_variable_from(result)
    	  end
    	  
        def dial(number, options={})
          set_caller_id options.delete(:caller_id)
          execute "Dial", number, options[:for], options[:options]
        end
        
        # def dial(number, options={})
        #   rules = callable_routes_for number
        #   return :no_route if rules.empty?
        #   call_attempt_status = nil
        #   rules.each do |provider|
        #     
        #     response = execute "Dial",
        #       provider.format_number_for_platform(number),
        #       timeout_from_dial_options(options),
        #       asterisk_options_from_dial_options(options)
        #       
        #     call_attempt_status = last_dial_status
        #     break if call_attempt_status == :answered
        #   end
        #   call_attempt_status
        # end
      	
      	def say_digits(digits)
      	  validate_digits(digits)
      	  execute("saydigits #{digits}")
      	end
      	
      	# Returns the number of seconds the given block takes to execute as a Float. This
      	# is particularly useful in dialplans for tracking billable time. Note that
      	# if the call is hung up during the block, you will need to rescue the
      	# exception if you have some mission-critical logic after it with which
      	# you're recording this return-value.
        def duration_of
          start_time = Time.now
          yield
          Time.now - start_time
        end

        private
        
          def set_caller_id(caller_id)
            return unless caller_id
            raise ArgumentError, "Caller ID must be numerical" if caller_id !~ /^\d+$/
            raw_response %(SET CALLERID %p) % caller_id
          end
          
          def timeout_from_dial_options(options)
            options[:for] || options[:timeout]
          end
          
          def asterisk_options_from_dial_options(options)
            # TODO: Will become much more sophisticated soon to handle callerid, etc
            options[:options]
          end
          
          def get_dial_status
            get_variable('DIALSTATUS').downcase.to_sym
          end
        
          def extract_input_from(result)
            return false if error?(result)
            # return false if input_timed_out?(result)
            result[/^#{response_prefix}([\d*]+)/, 1]
          end
          
          def extract_variable_from(result)
            return false if error?(result)
            result[/^#{response_prefix}1 \((.+)\)/, 1]
          end
          
          def play_time(argument)
            if argument.kind_of? Time
              execute(:sayunixtime, argument.to_i)
            end
          end
        
          def play_numeric(argument)
            if argument.kind_of?(Numeric) || argument =~ /^\d+$/
              execute(:saynumber, argument)
            end
          end
          
          def play_string(argument)
            execute(:playback, argument)
          end

          def to_pbx
            io
          end
          
          def from_pbx
            io
          end
          
          def validate_digits(digits)
            Integer(digits)
          rescue
            raise ArgumentError, "Can only be called with valid digits!"
          end
          
          def error?(result)
            result.to_s[/^#{response_prefix}(?:-\d+|0)/]
          end
          
          # timeout with pressed digits:    200 result=<digits> (timeout)
          # timeout without pressed digits: 200 result= (timeout)
          # (http://www.voip-info.org/wiki/view/get+data)
          def input_timed_out?(result)
            result[/^#{response_prefix}\d*\s\(timeout\)/]
          end
          
          def io
            call.io
          end
          
          def response_prefix
            RESPONSE_PREFIX
          end
          
          module SpeechEngines
            
            class InvalidSpeechEngine < Exception; end
            
            class << self
              def cepstral(text)
                puts "in ceptral"
                puts escape(text)
              end
              
              def festival(text)
                raise NotImplementedError
              end
              
              def none(text)
                raise InvalidSpeechEngine, "No speech engine selected. You must specify one in your Adhearsion config file."
              end
              
              def method_missing(engine_name, text)
                raise InvalidSpeechEngine, "Unsupported speech engine #{engine_name} for speaking '#{text}'"
              end
              
              private
              
              def escape(text)
                "%p" % text
              end
              
            end
          end
      end
    end
  end
end