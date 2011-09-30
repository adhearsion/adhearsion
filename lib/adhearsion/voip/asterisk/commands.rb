require 'adhearsion/voip/menu_state_machine/menu_class'
require 'json'

module Adhearsion
  module VoIP
    module Asterisk
      class AGIProtocolError < StandardError; end

      module Commands

        RESPONSE_PREFIX = "200 result=" unless defined? RESPONSE_PREFIX
        AGI_SUCCESSFUL_RESPONSE = RESPONSE_PREFIX + "1"

        # These are the status messages that asterisk will issue after a dial command is executed.
        #
        # Here is a current list of dial status messages which are not all necessarily supported by adhearsion:
        #
        # ANSWER: Call is answered. A successful dial. The caller reached the callee.
        # BUSY: Busy signal. The dial command reached its number but the number is busy.
        # NOANSWER: No answer. The dial command reached its number, the number rang for too long, then the dial timed out.
        # CANCEL: Call is cancelled. The dial command reached its number but the caller hung up before the callee picked up.
        # CONGESTION: Congestion. This status is usually a sign that the dialled number is not recognised.
        # CHANUNAVAIL: Channel unavailable. On SIP, peer may not be registered.
        # DONTCALL: Privacy mode, callee rejected the call
        # TORTURE: Privacy mode, callee chose to send caller to torture menu
        # INVALIDARGS: Error parsing Dial command arguments (added for Asterisk 1.4.1, SVN r53135-53136)
        #
        # @see http://www.voip-info.org/wiki/index.php?page=Asterisk+variable+DIALSTATUS Asterisk Variable DIALSTATUS
        DIAL_STATUSES   = Hash.new(:unknown).merge(:answer      => :answered, #:doc:
                                                   :congestion  => :congested,
                                                   :busy        => :busy,
                                                   :cancel      => :cancelled,
                                                   :noanswer    => :unanswered,
                                                   :cancelled   => :cancelled,
                                                   :chanunavail => :channel_unavailable) unless defined? DIAL_STATUSES

        DYNAMIC_FEATURE_EXTENSIONS = {
          :attended_transfer => lambda do |options|
            variable "TRANSFER_CONTEXT" => options[:context] if options && options.has_key?(:context)
            extend_dynamic_features_with "atxfer"
          end,
          :blind_transfer => lambda do |options|
            variable "TRANSFER_CONTEXT" => options[:context] if options && options.has_key?(:context)
            extend_dynamic_features_with 'blindxfer'
          end
        } unless defined? DYNAMIC_FEATURE_EXTENSIONS

        PLAYBACK_SUCCESS = 'SUCCESS' unless defined? PLAYBACK_SUCCESS

        # Utility method to write to pbx.
        # @param [String] message raw message
        def write(message)
          to_pbx.print message + "\n"
        end

        # Utility method to read from pbx. Hangup if nil.
        def read
          begin
            from_pbx.gets.tap do |message|
              # AGI has many conditions that might indicate a hangup
              raise Hangup if message.nil?

              ahn_log.agi.debug "<<< #{message}"

              code, rest = *message.split(' ', 2)

              case code.to_i
              when 510
                # This error is non-fatal for the call
                ahn_log.agi.warn "510: Invalid or unknown AGI command"
              when 511
                # 511 Command Not Permitted on a dead channel
                ahn_log.agi.debug "511: Dead channel. Raising Hangup"
                raise Hangup
              when 520
                # This error is non-fatal for the call
                ahn_log.agi.warn "520: Invalid command syntax"
              when (500..599)
                # Assume this error is non-fatal for the call and try to keep running
                ahn_log.agi.warn "#{code}: Unknown AGI protocol error."
              end

              # If the message starts with HANGUP it's a silly 1.6 OOB message
              case message
              when /^HANGUP/, /^HANGUP\n?$/i, /^HANGUP\s?\d{3}/i
                ahn_log.agi.debug "AGI HANGUP. Raising hangup"
                raise Hangup
              end
            end
          rescue Errno::ECONNRESET
            raise Hangup
          end
        end

        # The underlying method executed by nearly all the command methods in this module.
        # Used to send the plaintext commands in the proper AGI format over TCP/IP back to an Asterisk server via the
        # FAGI protocol.
        #
        # It is not recommended that you call this method directly unless you plan to write a new command method
        # in which case use this to communicate directly with an Asterisk server via the FAGI protocol.
        #
        # @param [String] message
        #
        # @see http://www.voip-info.org/wiki/view/Asterisk+FastAGI More information about FAGI
        def raw_response(message = nil)
          message.squish!
          @call.with_command_lock do
            raise ArgumentError.new("illegal NUL in message #{message.inspect}") if message =~ /\0/
            ahn_log.agi.debug ">>> #{message}"
            write message if message
            read
          end
        end

        def response(command, *arguments)
          if arguments.empty?
            raw_response("#{command}")
          else
            raw_response("#{command} " + arguments.map{ |arg| quote_arg(arg) }.join(' '))
          end
        end

        # Arguments surrounded by quotes; quotes backslash-escaped.
        # See parse_args in asterisk/res/res_agi.c (Asterisk 1.4.21.1)
        def quote_arg(arg)
          '"' + arg.to_s.gsub(/["\\]/) { |m| "\\#{m}" } + '"'
        end

        # Parses a response in the form of "200 result=some_value"
        def inline_return_value(result)
          return nil unless result
          case result.chomp
          when "200 result=0" then nil
          when /^200 result=(.*)$/ then $LAST_PAREN_MATCH
          else raise AGIProtocolError, "Invalid AGI response: #{result}"
          end
        end

        # Parses a response in the form of "200 result=0 (some_value)"
        def inline_result_with_return_value(result)
          return nil unless result
          case result.chomp
          when "200 result=0" then nil
          when /^#{AGI_SUCCESSFUL_RESPONSE} \((.*)\)$/ then $LAST_PAREN_MATCH
          else raise AGIProtocolError, "Invalid AGI response: #{result}"
          end
        end


        # This must be called first before any other commands can be issued.
        # In typical Adhearsion applications this is called by default as soon as a call is
        # transfered to a valid context in dialplan.rb.
        # If you do not want your Adhearsion application to automatically issue an answer command,
        # then you must edit your startup.rb file and configure this setting.
        # Keep in mind that you should not need to issue another answer command after one has already
        # been issued either explicitly by your code or implicitly by the standard adhearsion configuration.
        def answer
          response "ANSWER"
          true
        end

        # This asterisk dialplan command allows you to instruct Asterisk to start applications
        # which are typically run from extensions.conf.
        #
        # The most common commands are already made available through the FAGI interface provided
        # by this code base. For commands that do not fall into this category, then exec is what you
        # should use.
        #
        # For example, if there are specific asterisk modules you have loaded that will not be
        # available through the standard commands provided through FAGI - then you can used EXEC.
        #
        # @example Using execute in this way will add a header to an existing SIP call.
        #   execute 'SIPAddHeader', '"Call-Info: answer-after=0"
        #
        # @see http://www.voip-info.org/wiki/view/Asterisk+-+documentation+of+application+commands Asterisk Dialplan Commands
        def execute(application, *arguments)
          command = "EXEC #{application}"
          arguments = arguments.map { |arg| quote_arg(arg) }.join(AHN_CONFIG.asterisk.argument_delimiter)
          result = raw_response("#{command} #{arguments}")
          return false if error?(result)
          result
        end

        # Sends a message to the console via the verbose message system.
        #
        # @param [String] message
        # @param [Integer] level
        #
        # @return the result of the command
        #
        # @example Use this command to inform someone watching the Asterisk console
        # of actions happening within Adhearsion.
        #   verbose 'Processing call with Adhearsion' 3
        #
        # @see http://www.voip-info.org/wiki/view/verbose
        def verbose(message, level = nil)
            result = response('VERBOSE', message, level)
            return false if error?(result)
            result
        end

        # Hangs up the current channel. After this command is issued, you will not be able to send any more AGI
        # commands but the dialplan Thread will still continue, allowing you to do any post-call work.
        #
        def hangup
          response 'HANGUP'
        end

        # Plays the specified sound file names. This method will handle Time/DateTime objects (e.g. Time.now),
        # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. When playing
        # numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
        # is pronounced as "one hundred" instead of "one zero zero". To specify how the Date/Time objects are said
        # pass in as an array with the first parameter as the Date/Time/DateTime object along with a hash with the
        # additional options.  See play_time for more information.
        #
        # Note: it is not necessary to supply a sound file extension; Asterisk will try to find a sound
        # file encoded using the current channel's codec, if one exists. If not, it will transcode from
        # the default codec (GSM). Asterisk stores its sound files in /var/lib/asterisk/sounds.
        #
        # @example Play file hello-world.???
        #   play 'hello-world'
        # @example Speak current time
        #   play Time.now
        # @example Speak today's date
        #   play Date.today
        # @example Speak today's date in a specific format
        #   play [Date.today, {:format => 'BdY'}]
        # @example Play sound file, speak number, play two more sound files
        #   play %w"a-connect-charge-of 22 cents-per-minute will-apply"
        # @example Play two sound files
        #   play "you-sound-cute", "what-are-you-wearing"
        #
        # @return [Boolean] true is returned if everything was successful.  Otherwise, false indicates that
        #   some sound file(s) could not be played.
        def play(*arguments)
          result = true
          unless play_time(arguments)
            arguments.flatten.each do |argument|
              # result starts off as true.  But if the following command ever returns false, then result
              # remains false.
              result &= play_numeric(argument) || play_soundfile(argument)
            end
          end
          result
        end

        # Same as {#play}, but immediately raises an exception if a sound file cannot be played.
        #
        # @return [true]
        # @raise [Adhearsion::VoIP::PlaybackError] If a sound file cannot be played
        def play!(*arguments)
          unless play_time(arguments)
            arguments.flatten.each do |argument|
              play_numeric(argument) || play_soundfile!(argument)
            end
          end
          true
        end

        # Attempts to play a sound prompt.  If the prompt is unplayable, for
        # example, if the file is not present, then attempt to speak the prompt
        # using Text-To-Speech.
        #
        # @param [Hash] Map of prompts and fallback TTS options
        # @return [true]
        # @raise [ArgumentError] If prompt cannot be found and TTS text is not specified
        #
        # @example Play "tt-monkeys" or say "Ooh ooh eee eee eee"
        #   play_or_speak 'tt-monkeys' => {:text => "Ooh ooh eee eee eee"}
        #
        # @example Play "pbx-invalid" or say "I'm sorry, that is not a valid extension.  Please try again." and allowing the user to interrupt the TTS with "#"
        #   play_or_speak 'pbx-invalid' => {:text => "I'm sorry, that is not a valid extension.  Please try again", :engine => :unimrcp}
        def play_or_speak(prompts)
         interrupted = nil
         unless interrupted
           prompts.each do |filename, options|
            if filename && !filename.empty?
              begin
                if options[:interruptible]
                  interrupted = interruptible_play! filename
                else
                  play! filename
                end
              rescue PlaybackError
                raise ArgumentError, "Must supply TTS text as fallback" unless options[:text]
                interrupted = speak options.delete(:text), options
              end
            else
              interrupted = speak options.delete(:text), options
            end
           end
         end
         interrupted
        end

        # Records a sound file with the given name. If no filename is specified a file named by Asterisk
        # will be created and returned. Else the given filename will be returned. If a relative path is
        # given, the file will be saved in the default Asterisk sound directory, /var/lib/spool/asterisk
        # by default.
        #
        # @param [string] file name to record to.  Full path information is optional.  If you want to change the
        #   format of the file you will want to add a .<valid extention> to the end of the file name specifying the 
        #   filetype you want to record in.  Alternately you can pass it is as :format in the options
        #
        # @param [hash] options
        #
        # +:silence+ - silence in seconds
        #
        # +:maxduration+ - maximum duration in seconds
        #
        # +:escapedigits+ - digits to be used to excape from recording
        #
        # +:beep+ - soundfile to use as a beep before recording.  if not specifed defaults to system generated beep, set to nil for no beep.
        #
        # +:format+ - the format of the file to be recorded
        #
        # Silence and maxduration is specified in seconds.
        # 
        # @return [String] The filename of the recorded file.  
        #         
        # @example Asterisk generated filename
        #   filename = record
        # @example Specified filename
        #   record '/path/to/my-file.gsm'
        # @example All options specified
        #   record 'my-file.gsm', :silence => 5, :maxduration => 120
        # 
        # @deprecated please use {#record_to_file} instead
        def record(*args)
          options = args.last.kind_of?(Hash) ? args.last : {}
          filename = args.first && !args.first.kind_of?(Hash) ? String.new(args.first) : "/tmp/recording_%d"
          if filename.index("%d")
            if @call.variables.has_key?(:recording_counter)
              @call.variables[:recording_counter] += 1
            else
              @call.variables[:recording_counter]  = 0
            end
            filename = filename % @call.variables[:recording_counter]
            @call.variables[:recording_counter] -= 1
          end

          if (!options.has_key?(:format))
            format = filename.slice!(/\.[^\.]+$/)
            if (format.nil?)
              ahn_log.agi.warn "Format not specified and not detected.  Defaulting to \"gsm\""
              format = "gsm"
            end
            format.sub!(/^\./, "")
          else
            format = options[:format]
          end
          record_to_file(*args)
          filename + "." + format
        end

        # Records a sound file with the given name. If no filename is specified a file named by Asterisk
        # will be created and returned. Else the given filename will be returned. If a relative path is
        # given, the file will be saved in the default Asterisk sound directory, /var/lib/spool/asterisk
        # by default.
        #
        # @param [string] file name to record to.  Full path information is optional.  If you want to change the
        #   format of the file you will want to add a .<valid extention> to the end of the file name specifying the 
        #   filetype you want to record in.  If you don't specify a valid extension it will default to gsm and a
        #   .gsm will be added to the file.  If you don't specify a filename it will write one in /tmp/recording_%d
        #   with %d being a counter that increments from 0 onward for the particular call you are making.
        #
        # @param [hash] options
        #
        # +:silence+ - silence in seconds
        #
        # +:maxduration+ - maximum duration in seconds
        #
        # +:escapedigits+ - digits to be used to excape from recording
        #
        # +:beep+ - soundfile to use as a beep before recording.  if not specifed defaults to system generated beep, set to nil for no beep.
        #
        # +:format+ - the format of the file to be recorded.  This will over-ride a implicit format in a file extension and append a .<format> to the end of the file.
        #
        # Silence and maxduration is specified in seconds.
        # 
        # @return [Hash] With the following..... :status => {one of:hangup, :write_error, :success_dtmf, :success_timeout} :dtmf => {dtmf interruped key if :success_dtmf} 
        #        
        # A sound file will be recorded to the specifed file unless a :write_error is returned.  A :success_dtmf is
        # for when a call was ended with a DTMF tone.  A :success_timeout is returned when a call times out due to 
        # a silence longer than the specified silence or if the recording reaches the maxduration.
        #
        # @example Asterisk generated filename
        #   filename = record
        # @example Specified filename
        #   record '/path/to/my-file.gsm'
        # @example All options specified
        #   record 'my-file.gsm', :silence => 5, :maxduration => 120
        #
        def record_to_file(*args)
          base_record_to_file(*args)
        end

        # This works the same record_to_file except is throws an exception if a playback or write error occurs.
        #
        def record_to_file!(*args)
           # raise PlaybackError, "Playback failed with PLAYBACKSTATUS: #{playback.inspect}.  The raw response was #{response.inspect}."
          return_values = base_record_to_file(*args)
          if return_values[:error] == :playback_error
            raise PlaybackError, "Playback failed with PLAYBACKSTATUS: #{return_values[:raw_response].inspect}."
          elsif return_values[:status] == :write_error
            raise RecordError, "Record failed on write."
          end
          return_values
        end

        # this is a base methor record_to_file and record_to_file! and should only be used via those methods
        #
        def base_record_to_file(*args)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          filename = args.shift || "/tmp/recording_#{new_guid}_%d"

          if filename.index("%d")
            if @call.variables.has_key?(:recording_counter)
              @call.variables[:recording_counter] += 1
            else
              @call.variables[:recording_counter]  = 0
            end
            filename = filename % @call.variables[:recording_counter]
          end

          if (!options.has_key?(:format))
            format = filename.slice!(/\.[^\.]+$/)
            if (format.nil?)
              ahn_log.agi.warn "Format not specified and not detected.  Defaulting to \"gsm\""
              format = "gsm"
            end
            format.sub!(/^\./, "")
          else
            format = options.delete(:format)
          end

          # maxduration must be in milliseconds when using RECORD FILE
          maxduration = options.delete(:maxduration) || -1
          maxduration = maxduration * 1000 if maxduration > 0

          escapedigits = options.delete(:escapedigits) || "#"
          silence     = options.delete(:silence) || 0

          response_params = filename, format, escapedigits, maxduration, 0          
          response_values = {}
 
          if !options.has_key? :beep 
            response_params << 'BEEP'
          elsif options[:beep]
            play_soundfile options[:beep]
            playback_response = get_variable('PLAYBACKSTATUS')
            if playback_response != PLAYBACK_SUCCESS 
              response_values[:error] = :playback_error
              response_values[:raw_response] = playback_response
            end
          end

          if silence > 0
            response_params << "s=#{silence}"
          end

          resp = response 'RECORD FILE', *response_params
          # If the user hangs up before the recording is entered, -1 is returned by asterisk and RECORDED_FILE
          # will not contain the name of the file, even though it IS in fact recorded.
          if resp.match /hangup/
            response_values[:status] = :hangup
          elsif resp.match /writefile/
            response_values[:status] = :write_error 
          elsif resp.match /dtmf/
            response_values[:status] = :success_dtmf
          elsif resp.match /timeout/
            response_values[:status] = :success_timeout
          end

          response_values[:dtmf] = result_digit_from(resp) 
          response_values
        end

        # Simulates pressing the specified digits over the current channel. Can be used to
        # traverse a phone menu.
        def dtmf(digits)
          execute "SendDTMF", digits.to_s
        end

        # The with_next_message method...
        def with_next_message(&block)
          raise LocalJumpError, "Must supply a block" unless block_given?
          block.call(next_message)
        end

        # This command should be used to advance to the next message in the Asterisk Comedian Voicemail application
        def next_message
          @call.inbox.pop
        end

        # This command should be used to check if a message is waiting on the Asterisk Comedian Voicemail application.
        def messages_waiting?
          not @call.inbox.empty?
        end

        # Creates an interactive menu for the caller.
        #
        # The following documentation was derived from a post on Jay Phillips' blog (see below).
        #
        # The menu() command solves the problem of building enormous input-fetching state machines in Ruby without first-class
        # message passing facilities or an external DSL.
        #
        # Here is an example dialplan which uses the menu() command effectively.
        #
        #   from_pstn {
        #     menu 'welcome', 'for-spanish-press-8', 'main-ivr',
        #          :timeout => 8.seconds, :tries => 3 do |link|
        #       link.shipment_status  1
        #       link.ordering         2
        #       link.representative   4
        #       link.spanish          8
        #       link.employee         900..999
        #
        #       link.on_invalid { play 'invalid' }
        #
        #       link.on_premature_timeout do |str|
        #         play 'sorry'
        #       end
        #
        #       link.on_failure do
        #         play 'goodbye'
        #         hangup
        #       end
        #     end
        #   }
        #
        #   shipment_status {
        #     # Fetch a tracking number and pass it to a web service.
        #   }
        #
        #   ordering {
        #     # Enter another menu that lets them enter credit card
        #     # information and place their order over the phone.
        #   }
        #
        #   representative {
        #     # Place the caller into a queue
        #   }
        #
        #   spanish {
        #     # Special options for the spanish menu.
        #   }
        #
        #   employee {
        #     dial "SIP/#{extension}" # Overly simplistic
        #   }
        #
        # The main detail to note is the declarations within the menu() command’s block. Each line seems to refer to a link object
        # executing a seemingly arbitrary method with an argument that’s either a number or a Range of numbers. The +link+ object
        # collects these arbitrary method invocations and assembles a set of rules. The seemingly arbitrary method name is the name
        # of the context to which the menu should jump in case its argument (the pattern) is found to be a match.
        #
        # With these context names and patterns defined, the +menu()+ command plays in sequence the sound files you supply as
        # arguments, stopping playback abruptly if the user enters a digit. If no digits were pressed when the files finish playing,
        # it waits +:timeout+ seconds. If no digits are pressed after the timeout, it executes the +on_premature_timeout+ hook you
        # define (if any) and then tries again a maximum of +:tries+ times. If digits are pressed that result in no possible match,
        # it executes the +on_invalid+ hook. When/if all tries are exhausted with no positive match, it executes the +on_failure+
        # hook after the other hook (e.g. +on_invalid+, then +on_failure+).
        #
        # When the +menu()+ state machine runs through the defined rules, it must distinguish between exact and potential matches.
        # It's important to understand the differences between these and how they affect the overall outcome:
        #
        #   |---------------|-------------------|------------------------------------------------------|
        #   | exact matches | potential matches | result                                               |
        #   |---------------|-------------------|------------------------------------------------------|
        #   |  0            |  0                 | Fail and start over                                  |
        #   |  1            |  0                 | Match found!                                         |
        #   |  0            | >0                 | Get another digit                                    |
        #   | >1            |  0                 | Go with the first exact match                        |
        #   |  1            | >0                 | Get another digit. If timeout, use exact match       |
        #   | >1            | >0                 | Get another digit. If timeout, use first exact match |
        #   |---------------|-------------------|------------------------------------------------------|
        #
        # == Database integration
        #
        # To do database integration, I recommend programatically executing methods on the link object within the block. For example:
        #
        #   menu do |link|
        #     for employee in Employee.find(:all)
        #       link.internal employee.extension
        #     end
        #   end
        #
        # or this more efficient and Rubyish way
        #
        #   menu do |link|
        #     link.internal *Employee.find(:all).map(&:extension)
        #   end
        #
        # If this second example seems like too much Ruby magic, let me explain — +Employee.find(:all)+ effectively does a “SELECT *
        # FROM employees” on the database with ActiveRecord, returning (what you’d think is) an Array. The +map(&:extension)+ is
        # fanciness that means “replace every instance in this Array with the result of calling extension on that object”. Now we
        # have an Array of every extension in the database. The splat operator (*) before the argument changes the argument from
        # being one argument (an Array) into a sequence of n arguments, where n is the number of items in the Array it’s “splatting”.
        # Lastly, these arguments are passed to the internal method, the name of a context which will handle dialing this user if one
        # of the supplied patterns matches.
        #
        # == Handling a successful pattern match
        #
        # Which brings me to another important note. Let’s say that the user’s input successfully matched one of the patterns
        # returned by that Employe.find... magic. When it jumps to the internal context, that context can access the variable entered
        # through the extension variable. This was a tricky design decision that I think, overall, works great. It makes the +menu()+
        # command feel much more first-class in the Adhearsion dialplan grammar and decouples the receiving context from the menu
        # that caused the jump. After all, the context doesn’t necessary need to be the endpoint from a menu; it can be its own entry
        # point, making menu() effectively a pipeline of re-creating the call.
        #
        # @see http://jicksta.com/articles/2008/02/11/menu-command Original Blog Post
        def menu(*args, &block)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          sound_files = args.flatten

          menu_instance = Menu.new(options, &block)

          initial_digit_prompt = sound_files.any?

          # This method is basically one big begin/rescue block. When we start the Menu state machine by continue()ing, the state
          # machine will pass messages back to this method in the form of Exceptions. This decoupling allows the menu system to
          # work on, say, Freeswitch and Asterisk both.
          begin
            if menu_instance.should_continue?
              menu_instance.continue
            else
              menu_instance.execute_failure_hook
              return :failed
            end
          rescue Menu::MenuResult => result_of_menu
            case result_of_menu
              when Menu::MenuResultInvalid
                menu_instance.execute_invalid_hook
                menu_instance.restart!
              when Menu::MenuGetAnotherDigit

                next_digit = play_sound_files_for_menu(menu_instance, sound_files)
                if next_digit
                  menu_instance << next_digit
                else
                  # The user timed out entering another digit!
                  case result_of_menu
                    when Menu::MenuGetAnotherDigitOrFinish
                      # This raises a ControlPassingException
                      jump_to result_of_menu.match_payload, :extension => result_of_menu.new_extension
                    when Menu::MenuGetAnotherDigitOrTimeout
                      # This should execute premature_timeout AND reset if the number of retries
                      # has not been exhausted.
                      menu_instance.execute_timeout_hook
                      menu_instance.restart!
                  end
                end
              when Menu::MenuResultFound
                jump_to result_of_menu.match_payload, :extension => result_of_menu.new_extension
              else
                raise "Unrecognized MenuResult! This may be a bug!"
            end

            # Retry will re-execute the begin block, preserving our changes to the menu_instance object.
            retry

          end
        end

        # Used to receive keypad input from the user. Digits are collected
        # via DTMF (keypad) input until one of three things happens:
        #
        #  1. The number of digits you specify as the first argument is collected
        #  2. The timeout you specify with the :timeout option elapses.
        #  3. The "#" key (or the key you specify with :accept_key) is pressed
        #
        # Usage examples
        #
        #   input   # Receives digits until the caller presses the "#" key
        #   input 3 # Receives three digits. Can be 0-9, * or #
        #   input 5, :accept_key => "*"   # Receive at most 5 digits, stopping if '*' is pressed
        #   input 1, :timeout => 1.minute # Receive a single digit, returning an empty
        #                                   string if the timeout is encountered
        #   input 9, :timeout => 7, :accept_key => "0" # Receives nine digits, returning
        #                                              # when the timeout is encountered
        #                                              # or when the "0" key is pressed.
        #   input 3, :play => "you-sound-cute"
        #   input :play => ["if-this-is-correct-press", 1, "otherwise-press", 2]
        #   input :interruptible => false, :play => ["you-cannot-interrupt-this-message"] # Disallow DTMF (keypad) interruption
        #                                                                                 # until after all files are played.
        #
        # When specifying files to play, the playback of the sequence of files will stop
        # immediately when the user presses the first digit.
        #
        # The :timeout option works like a digit timeout, therefore each digit pressed
        # causes the timer to reset. This is a much more user-friendly approach than an
        # absolute timeout.
        #
        # Note that when the digit limit is not specified the :accept_key becomes "#".
        # Otherwise there would be no way to end the collection of digits. You can
        # obviously override this by passing in a new key with :accept_key.
        #
        # @return [String] The keypad input received. An empty string is returned in the
        #                  absense of input. If the :accept_key argument was pressed, it
        #                  will not appear in the output.
        def input(*args, &block)
          begin
            input! *args, &block
          rescue PlaybackError => e
            ahn_log.agi.warn { e }
            retry # If sound playback fails, play the remaining sound files and wait for digits
          end
        end

        # Same as {#input}, but immediately raises an exception if sound playback fails
        #
        # @return (see #input)
        # @raise [Adhearsion::VoIP::PlaybackError] If a sound file cannot be played
        def input!(*args, &block)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          number_of_digits = args.shift

          options[:play]  = [*options[:play]].compact

          if options.has_key?(:interruptible) && options[:interruptible] == false
            play_command = :play!
          else
            options[:interruptible] = true
            play_command = :interruptible_play!
          end

          if options.has_key? :speak
            raise ArgumentError unless options[:speak].is_a? Hash
            raise ArgumentError, 'Must include a text string when requesting TTS fallback' unless options[:speak].has_key?(:text)
            options[:speak][:interruptible] = options[:interruptible]
          end

          timeout         = options[:timeout]
          terminating_key = options[:accept_key]
          terminating_key = if terminating_key
            terminating_key.to_s
          elsif number_of_digits.nil? && !terminating_key.equal?(false)
            '#'
          end

          if number_of_digits && number_of_digits < 0
            ahn_log.agi.warn "Giving -1 to #input is now deprecated. Do not specify a first " +
                             "argument to allow unlimited digits." if number_of_digits == -1
            raise ArgumentError, "The number of digits must be positive!"
          end

          buffer = ''
          if options[:play].any?
            begin
              # Consume the sound files one at a time. In the event of playback
              # failure, this tells us which files remain unplayed.
              while file = options[:play].shift
                key = send play_command, file
                key = nil if play_command == :play!
                break if key
              end
            rescue PlaybackError
              raise unless options[:speak]
              key = speak options[:speak].delete(:text), options[:speak]
            end
            key ||= ''
          elsif options[:speak]
            key = speak(options[:speak].delete(:text), options[:speak]) || ''
          else
            key = wait_for_digit timeout || -1
          end
          loop do
            return buffer if key.nil?
            if terminating_key
              if key == terminating_key
                return buffer
              else
                buffer << key
                return buffer if number_of_digits && number_of_digits == buffer.length
              end
            else
              buffer << key
              return buffer if number_of_digits && number_of_digits == buffer.length
            end
            return buffer if block_given? && yield(buffer)
            key = wait_for_digit(timeout || -1)
          end
        end

        # Jumps to a context. An alternative to DialplanContextProc#+@. When jumping to a context, it will *not* resume executing
        # the former context when the jumped-to context has finished executing. Make sure you don't have any
        # +ensure+ closures which you expect to execute when the call has finished, as they will run when
        # this method is called.
        #
        # You can optionally override certain dialplan variables when jumping to the context. A popular use of
        # this is to redefine +extension+ (which this method automatically boxes with a PhoneNumber object) so
        # you can effectively "restart" a call (from the perspective of the jumped-to context). When you override
        # variables here, you're effectively blowing away the old variables. If you need them for some reason,
        # you should assign the important ones to an instance variable first before calling this method.
        def jump_to(context, overrides={})
          context = lookup_context_with_name(context) if context.kind_of?(Symbol) || (context.kind_of?(String) && context =~ /^[\w_]+$/)

          # JRuby has a bug that prevents us from correctly determining the class name.
          # See: http://jira.codehaus.org/browse/JRUBY-5026
          if !(context.kind_of?(Adhearsion::DialPlan::DialplanContextProc) || context.kind_of?(Proc))
            raise Adhearsion::VoIP::DSL::Dialplan::ContextNotFoundException
          end

          if overrides.any?
            overrides = overrides.symbolize_keys
            if overrides.has_key?(:extension) && !overrides[:extension].kind_of?(Adhearsion::VoIP::DSL::PhoneNumber)
              overrides[:extension] = Adhearsion::VoIP::DSL::PhoneNumber.new overrides[:extension]
            end

            overrides.each_pair do |key, value|
              meta_def(key) { value }
            end
          end

          raise Adhearsion::VoIP::DSL::Dialplan::ControlPassingException.new(context)
        end

        # Place a call in a queue to be answered by a registered agent. You must then call join!()
        #
        # @param [String] queue_name the queue name to place the caller in
        # @return [Adhearsion::VoIP::Asterisk::Commands::QueueProxy] a queue proxy object
        #
        # @see http://www.voip-info.org/wiki-Asterisk+cmd+Queue Full information on the Asterisk Queue
        # @see Adhearsion::VoIP::Asterisk::Commands::QueueProxy#join! join!() for further details
        def queue(queue_name)
          queue_name = queue_name.to_s

          @queue_proxy_hash_lock = Mutex.new unless defined? @queue_proxy_hash_lock
          @queue_proxy_hash_lock.synchronize do
            @queue_proxy_hash ||= {}
            if @queue_proxy_hash.has_key? queue_name
              return @queue_proxy_hash[queue_name]
            else
              proxy = @queue_proxy_hash[queue_name] = QueueProxy.new(queue_name, self)
              return proxy
            end
          end
        end

        # Get the status of the last dial(). Possible dial statuses include :answer,
        # :busy, :no_answer, :cancelled, :congested, and :channel_unavailable.
        # If :cancel is returned, the caller hung up before the callee picked up.
        # If :congestion is returned, the dialed extension probably doesn't exist.
        # If :channel_unavailable, the callee phone may not be registered.
        def last_dial_status
          DIAL_STATUSES[get_dial_status]
        end

        # @return [Boolean] true if your last call to dial() finished with the ANSWER state,
        # as reported by Asterisk. false otherwise
        def last_dial_successful?
          last_dial_status == :answered
        end

        # Opposite of last_dial_successful?()
        def last_dial_unsuccessful?
          not last_dial_successful?
        end

        ##
        # @param [#to_s] text to speak using the TTS engine
        # @param [Hash] options
        # @param options [Symbol] :engine the engine to use. Currently supported engines are :cepstral and :unimrcp
        # @param options [String] :barge_in_digits digits to allow the TTS to be interrupted with
        #
        def speak(text, options = {})
          engine = options.delete(:engine) || AHN_CONFIG.asterisk.speech_engine || :none
          options[:interruptible] = false unless options.has_key?(:interruptible)
          SpeechEngines.send(engine, self, text.to_s, options)
        end

        module SpeechEngines
          class InvalidSpeechEngine < StandardError; end

          class << self
            def cepstral(call, text, options = {})
              # We need to aggressively escape commas so app_swift does not
              # think they are arguments.
              text.gsub! /,/, '\\\\,'
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

        # A high-level way of enabling features you create/uncomment from features.conf.
        #
        # Certain Symbol features you enable (as defined in DYNAMIC_FEATURE_EXTENSIONS) have optional
        # arguments that you can also specify here. The usage examples show how to do this.
        #
        # Usage examples:
        #
        #   enable_feature :attended_transfer                        # Enables "atxfer"
        #
        #   enable_feature :attended_transfer, :context => "my_dial" # Enables "atxfer" and then
        #                                                            # sets "TRANSFER_CONTEXT" to :context's value
        #
        #   enable_feature :blind_transfer, :context => 'my_dial'    # Enables 'blindxfer' and sets TRANSFER_CONTEXT
        #
        #   enable_feature "foobar"                                  # Enables "foobar"
        #
        #   enable_feature("dup"); enable_feature("dup")             # Enables "dup" only once.
        def enable_feature(feature_name, optional_options=nil)
          if DYNAMIC_FEATURE_EXTENSIONS.has_key? feature_name
            instance_exec(optional_options, &DYNAMIC_FEATURE_EXTENSIONS[feature_name])
          else
            raise ArgumentError, "You cannot supply optional options when the feature name is " +
                                 "not internally recognized!" if optional_options
            extend_dynamic_features_with feature_name
          end
        end

        # Disables a feature name specified in features.conf. If you're disabling it, it was probably
        # set by enable_feature().
        #
        # @param [String] feature_name
        def disable_feature(feature_name)
          enabled_features_variable = variable 'DYNAMIC_FEATURES'
          enabled_features = enabled_features_variable.split('#')
          if enabled_features.include? feature_name
            enabled_features.delete feature_name
            variable 'DYNAMIC_FEATURES' => enabled_features.join('#')
          end
        end

        # Used to join a particular conference with the MeetMe application. To use MeetMe, be sure you
        # have a proper timing device configured on your Asterisk box. MeetMe is Asterisk's built-in
        # conferencing program.
        #
        # @param [String] conference_id
        # @param [Hash] options
        #
        # @see http://www.voip-info.org/wiki-Asterisk+cmd+MeetMe Asterisk Meetme Application Information
        def join(conference_id, options={})
          conference_id = conference_id.to_s.scan(/\w/).join
          command_flags = options[:options].to_s # This is a passthrough string straight to Asterisk
          pin = options[:pin]
          raise ArgumentError, "A conference PIN number must be numerical!" if pin && pin.to_s !~ /^\d+$/

          # To disable dynamic conference creation set :use_static_conf => true
          use_static_conf = options.has_key?(:use_static_conf) ? options[:use_static_conf] : false

          # The 'd' option of MeetMe creates conferences dynamically.
          command_flags += 'd' unless (command_flags.include?('d') or use_static_conf)

          execute "MeetMe", conference_id, command_flags, options[:pin]
        end

        # Issue this command to access a channel variable that exists in the asterisk dialplan (i.e. extensions.conf)
        # Use get_variable to pass information from other modules or high level configurations from the asterisk dialplan
        # to the adhearsion dialplan.
        #
        # @param [String] variable_name
        #
        # @see: http://www.voip-info.org/wiki/view/get+variable Asterisk Get Variable
        def get_variable(variable_name)
          inline_result_with_return_value response "GET VARIABLE", variable_name
        end

        # Pass information back to the asterisk dial plan.
        #
        # Keep in mind that the variables are not global variables. These variables only exist for the channel
        # related to the call that is being serviced by the particular instance of your adhearsion application.
        # You will not be able to pass information back to the asterisk dialplan for other instances of your adhearsion
        # application to share. Once the channel is "hungup" then the variables are cleared and their information is gone.
        #
        # @param [String] variable_name
        # @param [String] value
        #
        # @see http://www.voip-info.org/wiki/view/set+variable Asterisk Set Variable
        def set_variable(variable_name, value)
          response("SET VARIABLE", variable_name, value) == AGI_SUCCESSFUL_RESPONSE
        end

        # Issue the command to add a custom SIP header to the current call channel
        # example use: sip_add_header("x-ahn-test", "rubyrox")
        #
        # @param[String] the name of the SIP header
        # @param[String] the value of the SIP header
        #
        # @return [String] the Asterisk response
        #
        # @see http://www.voip-info.org/wiki/index.php?page=Asterisk+cmd+SIPAddHeader Asterisk SIPAddHeader
        def sip_add_header(header, value)
          execute("SIPAddHeader", "#{header}: #{value}") == AGI_SUCCESSFUL_RESPONSE
        end

        # Issue the command to fetch a SIP header from the current call channel
        # example use: sip_get_header("x-ahn-test")
        #
        # @param[String] the name of the SIP header to get
        #
        # @return [String] the Asterisk response
        #
        # @see http://www.voip-info.org/wiki/index.php?page=Asterisk+cmd+SIPGetHeader Asterisk SIPGetHeader
        def sip_get_header(header)
          get_variable("SIP_HEADER(#{header})")
        end
        alias :sip_header :sip_get_header

        # Allows you to either set or get a channel variable from Asterisk.
        # The method takes a hash key/value pair if you would like to set a variable
        # Or a single string with the variable to get from Asterisk
        def variable(*args)
          if args.last.kind_of? Hash
            assignments = args.pop
            raise ArgumentError, "Can't mix variable setting and fetching!" if args.any?
            assignments.each_pair do |key, value|
              set_variable(key, value)
            end
          else
            if args.size == 1
              get_variable args.first
            else
              args.map { |var| get_variable(var) }
            end
          end
        end

        # Send a caller to a voicemail box to leave a message.
        #
        # The method takes the mailbox_number of the user to leave a message for and a
        # greeting_option that will determine which message gets played to the caller.
        #
        # @see http://www.voip-info.org/tiki-index.php?page=Asterisk+cmd+VoiceMail Asterisk Voicemail
        def voicemail(*args)
          options_hash    = args.last.kind_of?(Hash) ? args.pop : {}
          mailbox_number  = args.shift
          greeting_option = options_hash.delete(:greeting)
          skip_option     = options_hash.delete(:skip)
          raise ArgumentError, 'You supplied too many arguments!' if mailbox_number && options_hash.any?
          greeting_option = case greeting_option
            when :busy then 'b'
            when :unavailable then 'u'
            when nil then nil
            else raise ArgumentError, "Unrecognized greeting #{greeting_option}"
          end
          skip_option &&= 's'
          options = "#{greeting_option}#{skip_option}"

          raise ArgumentError, "Mailbox cannot be blank!" if !mailbox_number.nil? && mailbox_number.blank?
          number_with_context = if mailbox_number then mailbox_number else
            raise ArgumentError, "You must supply ONE context name!" if options_hash.size != 1
            context_name, mailboxes = options_hash.to_a.first
            Array(mailboxes).map do |mailbox|
              raise ArgumentError, "Mailbox numbers must be numerical!" unless mailbox.to_s =~ /^\d+$/
              "#{mailbox}@#{context_name}"
            end.join('&')
          end
          execute('voicemail', number_with_context, options)
          case variable('VMSTATUS')
            when 'SUCCESS' then true
            when 'USEREXIT' then false
            else nil
          end
        end

        # The voicemail_main method puts a caller into the voicemail system to fetch their voicemail
        # or set options for their voicemail box.
        #
        # @param [Hash] options
        #
        # @see http://www.voip-info.org/wiki-Asterisk+cmd+VoiceMailMain Asterisk VoiceMailMain Command
        def voicemail_main(options={})
          mailbox, context, folder = options.values_at :mailbox, :context, :folder
          authenticate = options.has_key?(:authenticate) ? options[:authenticate] : true

          folder = if folder
            if folder.to_s =~ /^[\w_]+$/
              "a(#{folder})"
            else
              raise ArgumentError, "Voicemail folder must be alphanumerical/underscore characters only!"
            end
          elsif folder == ''
            raise "Folder name cannot be an empty String!"
          else
            nil
          end

          real_mailbox = ""
          real_mailbox << "#{mailbox}"  unless mailbox.blank?
          real_mailbox << "@#{context}" unless context.blank?

          real_options = ""
          real_options << "s" if !authenticate
          real_options << folder unless folder.blank?

          command_args = [real_mailbox]
          command_args << real_options unless real_options.blank?
          command_args.clear if command_args == [""]

          execute 'VoiceMailMain', *command_args
        end

        def check_voicemail
          ahn_log.agi.warn "THE check_voicemail() DIALPLAN METHOD WILL SOON BE DEPRECATED! CHANGE THIS TO voicemail_main() INSTEAD"
          voicemail_main
        end

        # Dial an extension or "phone number" in asterisk.
        # Maps to the Asterisk DIAL command in the asterisk dialplan.
        #
        # @param [String] number represents the extension or "number" that asterisk should dial.
        # Be careful to not just specify a number like 5001, 9095551001
        # You must specify a properly formatted string as Asterisk would expect to use in order to understand
        # whether the call should be dialed using SIP, IAX, or some other means.
        #
        # @param [Hash] options
        #
        # +:caller_id+ - the caller id number to be used when the call is placed.  It is advised you properly adhere to the
        # policy of VoIP termination providers with respect to caller id values.
        #
        # +:name+ - this is the name which should be passed with the caller ID information
        # if :name=>"John Doe" and :caller_id => "444-333-1000" then the compelete CID and name would be "John Doe" <4443331000>
        # support for caller id information varies from country to country and from one VoIP termination provider to another.
        #
        # +:for+ - this option can be thought of best as a timeout.  i.e. timeout after :for if no one answers the call
        # For example, dial("SIP/jay-desk-650&SIP/jay-desk-601&SIP/jay-desk-601-2", :for => 15.seconds, :caller_id => callerid)
        # this call will timeout after 15 seconds if 1 of the 3 extensions being dialed do not pick prior to the 15 second time limit
        #
        # +:options+ - This is a string of options like "Tr" which are supported by the asterisk DIAL application.
        # for a complete list of these options and their usage please check the link below.
        #
        # +:confirm+ - ?
        #
        # @example Make a call to the PSTN using my SIP provider for VoIP termination
        #   dial("SIP/19095551001@my.sip.voip.terminator.us")
        #
        # @example Make 3 Simulataneous calls to the SIP extensions separated by & symbols, try for 15 seconds and use the callerid
        # for this call specified by the variable my_callerid
        #   dial "SIP/jay-desk-650&SIP/jay-desk-601&SIP/jay-desk-601-2", :for => 15.seconds, :caller_id => my_callerid
        #
        # @example Make a call using the IAX provider to the PSTN
        #   dial("IAX2/my.id@voipjet/19095551234", :name=>"John Doe", :caller_id=>"9095551234")
        #
        # @see http://www.voip-info.org/wiki-Asterisk+cmd+Dial Asterisk Dial Command
        def dial(number, options={})
          *recognized_options = :caller_id, :name, :for, :options, :confirm

          unrecognized_options = options.keys - recognized_options
          raise ArgumentError, "Unknown dial options: #{unrecognized_options.to_sentence}" if unrecognized_options.any?
          set_caller_id_name options[:name]
          set_caller_id_number options[:caller_id]
          confirm_option = dial_macro_option_compiler options[:confirm]
          all_options = options[:options]
          all_options = all_options ? all_options + confirm_option : confirm_option
          execute "Dial", number, options[:for], all_options
        end


        # This implementation of dial() uses the experimental call routing DSL.
        #
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


        # Speaks the digits given as an argument. For example, "123" is spoken as "one two three".
        #
        # @param [String] digits
        def say_digits(digits)
          execute "saydigits", validate_digits(digits)
        end

        # Get the number of seconds the given block takes to execute. This
        # is particularly useful in dialplans for tracking billable time. Note that
        # if the call is hung up during the block, you will need to rescue the
        # exception if you have some mission-critical logic after it with which
        # you're recording this return-value.
        #
        # @return [Float] number of seconds taken for block to execute
        def duration_of
          start_time = Time.now
          yield
          Time.now - start_time
        end

        #
        # Play a sequence of files, stopping the playback if a digit is pressed.
        #
        # @return [String, nil] digit pressed, or nil if none
        #
        def interruptible_play(*files)
          result = nil
          files.flatten.each do |file|
            begin
              result = interruptible_play!(file)
            rescue PlaybackError => e
              # Ignore this exception and play the next file
              ahn_log.agi.warn e.message
            ensure
              break if result
            end
          end
          result
        end

        #
        # Same as {#interruptible_play}, but immediately raises an exception if a sound file cannot be played.
        #
        # @return (see #interruptible_play)
        # @raise [Adhearsion::VoIP::PlaybackError] If a sound file cannot be played
        def interruptible_play!(*files)
          startpos = 0
          files.flatten.each do |file|
            result = stream_file_result_from response("STREAM FILE", file, "1234567890*#")
            if result[:endpos].to_i <= startpos
              raise Adhearsion::VoIP::PlaybackError, "The sound file could not opened to stream.  The parsed response was #{result.inspect}"
            end
            return result[:digit] if result.has_key? :digit
          end
          nil
        end

        ##
        # Executes the SayPhonetic command. This command will read the text passed in
        # out load using the NATO phonetic alphabet.
        #
        # @param [String] Passed in as the text to read aloud
        #
        # @see http://www.voip-info.org/wiki/view/Asterisk+cmd+SayPhonetic Asterisk SayPhonetic Command
        def say_phonetic(text)
          execute "sayphonetic", text
        end

        ##
        # Executes the SayAlpha command. This command will read the text passed in
        # out loud, character-by-character.
        #
        # @param [String] Passed in as the text to read aloud
        #
        # @example Say "one a two dot pound"
        #   say_chars "1a2.#"
        #
        # @see http://www.voip-info.org/wiki/view/Asterisk+cmd+SayAlpha Asterisk SayPhonetic Command
        def say_chars(text)
          execute "sayalpha", text
        end

        # Plays the given Date, Time, or Integer (seconds since epoch)
        # using the given timezone and format.
        #
        # @param [Date|Time|DateTime] Time to be said.
        # @param [Hash] Additional options to specify how exactly to say time specified.
        #
        # +:timezone+ - Sends a timezone to asterisk. See /usr/share/zoneinfo for a list. Defaults to the machine timezone.
        # +:format+   - This is the format the time is to be said in.  Defaults to "ABdY 'digits/at' IMp"
        #
        # @see http://www.voip-info.org/wiki/view/Asterisk+cmd+SayUnixTime
        def play_time(*args)
          argument, options = args.flatten
          options ||= {}

          return false unless options.is_a? Hash

          timezone = options.delete(:timezone) || ''
          format   = options.delete(:format)   || ''
          epoch    = case argument
                     when Time || DateTime
                       argument.to_i
                     when Date
                       format = 'BdY' unless format.present?
                       argument.to_time.to_i
                     end

          return false if epoch.nil?

          execute :sayunixtime, epoch, timezone, format
        end

        protected

          # wait_for_digits waits for the input of digits based on the number of milliseconds
          def wait_for_digit(timeout=-1)
            timeout *= 1_000 if timeout != -1
            result = result_digit_from response("WAIT FOR DIGIT", timeout.to_i)
            (result == 0.chr) ? nil : result
          end

          ##
          # Deprecated name of interruptible_play(). This is a misspelling!
          #
          def interruptable_play(*files)
            ahn_log.deprecation.warn 'Please change your code to use interruptible_play() instead. "interruptable" is a misspelling! interruptable_play() will work for now but will be deprecated in the future!'
            interruptible_play(*files)
          end

          # allows setting of the callerid number of the call
          def set_caller_id_number(caller_id_num)
            return unless caller_id_num
            raise ArgumentError, "Caller ID must be numeric" if caller_id_num.to_s !~ /^\+?\d+$/
            variable "CALLERID(num)" => caller_id_num
          end

          # allows the setting of the callerid name of the call
          def set_caller_id_name(caller_id_name)
            return unless caller_id_name
            variable "CALLERID(name)" => caller_id_name
          end

          def timeout_from_dial_options(options)
            options[:for] || options[:timeout]
          end

          def asterisk_options_from_dial_options(options)
            # TODO: Will become much more sophisticated soon to handle callerid, etc
            options[:options]
          end

          def dial_macro_option_compiler(confirm_argument_value)
            defaults = { :macro => 'ahn_dial_confirmer',
                         :timeout => 20.seconds,
                         :play => "beep",
                         :key => '#' }

            case confirm_argument_value
              when true
                DialPlan::ConfirmationManager.encode_hash_for_dial_macro_argument(defaults)
              when false, nil
                ''
              when Proc
                raise NotImplementedError, "Coming in the future, you can do :confirm => my_context."

              when Hash
                options = defaults.merge confirm_argument_value
                if((confirm_argument_value.keys - defaults.keys).any?)
                  raise ArgumentError, "Known options: #{defaults.keys.to_sentence}"
                end
                raise ArgumentError, "Bad macro name!" unless options[:macro].to_s =~ /^[\w_]+$/
                options[:timeout] = case options[:timeout]
                  when Fixnum, ActiveSupport::Duration
                    options[:timeout]
                  when String
                    raise ArgumentError, "Timeout must be numerical!" unless options[:timeout] =~ /^\d+$/
                    options[:timeout].to_i
                  when :none
                    0
                  else
                    raise ArgumentError, "Unrecognized :timeout! #{options[:timeout].inspect}"
                end
                raise ArgumentError, "Unrecognized DTMF key: #{options[:key]}" unless options[:key].to_s =~ /^[\d#*]$/
                options[:play] = Array(options[:play]).join('++')
                DialPlan::ConfirmationManager.encode_hash_for_dial_macro_argument options

              else
                raise ArgumentError, "Unrecognized :confirm option: #{confirm_argument_value.inspect}!"
            end
          end

          def result_digit_from(response_string)
            raise ArgumentError, "Can't coerce nil into AGI response! This could be a bug!" unless response_string
            digit = response_string[/^#{response_prefix}(-?\d+(\.\d+)?)/,1]
            digit.to_i.chr if digit && digit.to_s != "-1"
          end

          def stream_file_result_from(response_string)
            raise ArgumentError, "Can't coerce nil into AGI response! This could be a bug!" unless response_string
            params = {}
            digit, endpos = response_string.match(/^#{response_prefix}(-?\d+) endpos=(\d+)/).values_at 1, 2
            params[:digit] = digit.to_i.chr unless digit == "0" || digit.to_s == "-1"
            params[:endpos] = endpos.to_i if endpos
            params
          end

          def extract_input_from(result)
            return false if error?(result)
            # return false if input_timed_out?(result)

            # This regexp doesn't match if there was a timeout with no
            # inputted digits, therefore returning nil.

            result[/^#{response_prefix}([\d*]+)/, 1]
          end

          def extract_variable_from(result)
            return false if error?(result)
            result[/^#{response_prefix}1 \((.+)\)/, 1]
          end

          def get_dial_status
            dial_status = variable('DIALSTATUS')
            dial_status ? dial_status.downcase.to_sym : :cancelled
          end


          def play_numeric(argument)
            if argument.kind_of?(Numeric) || argument =~ /^\d+$/
              execute(:saynumber, argument)
            end
          end

          # Instruct Asterisk to play a sound file to the channel
          def play_soundfile(argument)
            execute(:playback, argument)
            get_variable('PLAYBACKSTATUS') == PLAYBACK_SUCCESS
          end
          alias :play_string :play_soundfile

          # Like play_soundfile, but this will raise Exceptions if there's a problem.
          #
          # @return [true]
          # @raise [Adhearsion::VoIP::PlaybackError] If a sound file cannot be played
          # @see http://www.voip-info.org/wiki/view/Asterisk+cmd+Playback More information on the Asterisk Playback command
          def play_soundfile!(argument)
            response = execute :playback, argument
            playback = get_variable 'PLAYBACKSTATUS'
            return true if playback == PLAYBACK_SUCCESS
            raise PlaybackError, "Playback failed with PLAYBACKSTATUS: #{playback.inspect}.  The raw response was #{response.inspect}."
          end
          alias :play_string! :play_soundfile!

          def play_sound_files_for_menu(menu_instance, sound_files)
            digit = nil
            if sound_files.any? && menu_instance.digit_buffer_empty?
              digit = interruptible_play(*sound_files)
            end
            digit || wait_for_digit(menu_instance.timeout)
          end

          def extend_dynamic_features_with(feature_name)
            current_variable = variable("DYNAMIC_FEATURES") || ''
            enabled_features = current_variable.split '#'
            unless enabled_features.include? feature_name
              enabled_features << feature_name
              variable "DYNAMIC_FEATURES" => enabled_features.join('#')
            end
          end

          def jump_to_context_with_name(context_name)
            context_lambda = lookup_context_with_name context_name
            raise Adhearsion::VoIP::DSL::Dialplan::ControlPassingException.new(context_lambda)
          end

          def lookup_context_with_name(context_name)
            begin
              send context_name
            rescue NameError
              raise Adhearsion::VoIP::DSL::Dialplan::ContextNotFoundException
            end
          end

          def redefine_extension_to_be(new_extension)
            new_extension = Adhearsion::VoIP::DSL::PhoneNumber.new new_extension
            meta_def(:extension) { new_extension }
          end

          def to_pbx
            io
          end

          def from_pbx
            io
          end

          def validate_digits(digits)
            digits.to_s.tap do |digits_as_string|
              raise ArgumentError, "Can only be called with valid digits!" unless digits_as_string =~ /^[0-9*#-]+$/
            end
          end

          def error?(result)
            result.to_s[/^#{response_prefix}(?:-\d+)/]
          end

          # timeout with pressed digits:    200 result=<digits> (timeout)
          # timeout without pressed digits: 200 result= (timeout)
          # @see http://www.voip-info.org/wiki/view/get+data AGI Get Data
         def input_timed_out?(result)
            result.starts_with?(response_prefix) && result.ends_with?('(timeout)')
          end

          def io
            call.io
          end

          def response_prefix
            RESPONSE_PREFIX
          end

          class QueueProxy

            class << self

              def format_join_hash_key_arguments(options)

                bad_argument = lambda do |(key, value)|
                  raise ArgumentError, "Unrecognize value for #{key.inspect} -- #{value.inspect}"
                end

                # Direct Queue() arguments:
                timeout        = options.delete :timeout
                announcement   = options.delete :announce

                # Terse single-character options
                ring_style     = options.delete :play
                allow_hangup   = options.delete :allow_hangup
                allow_transfer = options.delete :allow_transfer
                agi            = options.delete :agi

                raise ArgumentError, "Unrecognized args to join!: #{options.inspect}" if options.any?

                ring_style = case ring_style
                  when :ringing then 'r'
                  when :music then   ''
                  when nil
                  else bad_argument[:play => ring_style]
                end.to_s

                allow_hangup = case allow_hangup
                  when :caller then   'H'
                  when :agent then    'h'
                  when :everyone then 'Hh'
                  when nil
                  else bad_argument[:allow_hangup => allow_hangup]
                end.to_s

                allow_transfer = case allow_transfer
                  when :caller then   'T'
                  when :agent then    't'
                  when :everyone then 'Tt'
                  when nil
                  else bad_argument[:allow_transfer => allow_transfer]
                end.to_s

                terse_character_options = ring_style + allow_transfer + allow_hangup

                [terse_character_options, '', announcement, timeout, agi].map(&:to_s)
              end

            end

            attr_reader :name, :environment
            def initialize(name, environment)
              @name, @environment = name, environment
            end

            # Makes the current channel join the queue.
            #
            # @param [Hash] options
            #
            #   :timeout        - The number of seconds to wait for an agent to answer
            #   :play           - Can be :ringing or :music.
            #   :announce       - A sound file to play instead of the normal queue announcement.
            #   :allow_transfer - Can be :caller, :agent, or :everyone. Allow someone to transfer the call.
            #   :allow_hangup   - Can be :caller, :agent, or :everyone. Allow someone to hangup with the * key.
            #   :agi            - An AGI script to be called on the calling parties channel just before being connected.
            #
            #  @example
            #    queue('sales').join!
            #  @example
            #    queue('sales').join! :timeout => 1.minute
            #  @example
            #    queue('sales').join! :play => :music
            #  @example
            #    queue('sales').join! :play => :ringing
            #  @example
            #    queue('sales').join! :announce => "custom/special-queue-announcement"
            #  @example
            #    queue('sales').join! :allow_transfer => :caller
            #  @example
            #    queue('sales').join! :allow_transfer => :agent
            #  @example
            #    queue('sales').join! :allow_hangup   => :caller
            #  @example
            #    queue('sales').join! :allow_hangup   => :agent
            #  @example
            #    queue('sales').join! :allow_hangup   => :everyone
            #  @example
            #    queue('sales').join! :agi            => 'agi://localhost/sales_queue_callback'
            #  @example
            #    queue('sales').join! :allow_transfer => :agent, :timeout => 30.seconds,
            def join!(options={})
              environment.execute("queue", name, *self.class.format_join_hash_key_arguments(options))
              normalize_queue_status_variable environment.variable("QUEUESTATUS")
            end

            # Get the agents associated with a queue
            #
            # @param [Hash] options
            # @return [QueueAgentsListProxy]
            def agents(options={})
              cached = options.has_key?(:cache) ? options.delete(:cache) : true
              raise ArgumentError, "Unrecognized arguments to agents(): #{options.inspect}" if options.keys.any?
              if cached
                @cached_proxy ||= QueueAgentsListProxy.new(self, true)
              else
                @uncached_proxy ||=  QueueAgentsListProxy.new(self, false)
              end
            end

            # Check how many channels are waiting in the queue
            # @return [Integer]
            # @raise QueueDoesNotExistError
            def waiting_count
              raise QueueDoesNotExistError.new(name) unless exists?
              environment.variable("QUEUE_WAITING_COUNT(#{name})").to_i
            end

            # Check whether the waiting count is zero
            # @return [Boolean]
            def empty?
              waiting_count == 0
            end

            # Check whether any calls are waiting in the queue
            # @return [Boolean]
            def any?
              waiting_count > 0
            end

            # Check whether a queue exists/is defined in Asterisk
            # @return [Boolean]
            def exists?
              environment.execute('RemoveQueueMember', name, 'SIP/AdhearsionQueueExistenceCheck')
              environment.variable("RQMSTATUS") != 'NOSUCHQUEUE'
            end

            private

            # Ensure the queue exists by interpreting the QUEUESTATUS variable
            #
            # According to http://www.voip-info.org/wiki/view/Asterisk+cmd+Queue
            # possible values are:
            #
            # TIMEOUT      => :timeout
            # FULL         => :full
            # JOINEMPTY    => :joinempty
            # LEAVEEMPTY   => :leaveempty
            # JOINUNAVAIL  => :joinunavail
            # LEAVEUNAVAIL => :leaveunavail
            # CONTINUE     => :continue
            #
            # If the QUEUESTATUS variable is not set the call was successfully connected,
            # and Adhearsion will return :completed.
            #
            # @param [String] QUEUESTATUS variable from Asterisk
            # @return [Symbol] Symbolized version of QUEUESTATUS
            # @raise QueueDoesNotExistError
            def normalize_queue_status_variable(variable)
              variable = "COMPLETED" if variable.nil?
              variable.downcase.to_sym
            end

            class QueueAgentsListProxy

              include Enumerable

              attr_reader :proxy, :agents
              def initialize(proxy, cached=false)
                @proxy  = proxy
                @cached = cached
              end

              def count
                if cached? && @cached_count
                  @cached_count
                else
                  @cached_count = proxy.environment.variable("QUEUE_MEMBER_COUNT(#{proxy.name})").to_i
                end
              end
              alias size count
              alias length count

              # @param [Hash] args
              # :name value will be viewable in the queue_log
              # :penalty is the penalty assigned to this agent for answering calls on this queue
              def new(*args)

                options   = args.last.kind_of?(Hash) ? args.pop : {}
                interface = args.shift

                raise ArgumentError, "You must specify an interface to add." if interface.nil?
                raise ArgumentError, "You may only supply an interface and a Hash argument!" if args.any?

                penalty             = options.delete(:penalty)            || ''
                name                = options.delete(:name)               || ''
                state_interface     = options.delete(:state_interface)    || ''

                raise ArgumentError, "Unrecognized argument(s): #{options.inspect}" if options.any?

                proxy.environment.execute("AddQueueMember", proxy.name, interface, penalty, '', name, state_interface)

                added = case proxy.environment.variable("AQMSTATUS")
                        when "ADDED"         then true
                        when "MEMBERALREADY" then false
                        when "NOSUCHQUEUE"   then raise QueueDoesNotExistError.new(proxy.name)
                        else
                          raise "UNRECOGNIZED AQMSTATUS VALUE!"
                        end

                if added
                  check_agent_cache!
                  AgentProxy.new(interface, proxy).tap do |agent_proxy|
                    @agents << agent_proxy
                  end
                else
                  false
                end
              end

              # Logs a pre-defined agent into this queue and waits for calls. Pass in :silent => true to stop
              # the message which says "Agent logged in".
              def login!(*args)
                options = args.last.kind_of?(Hash) ? args.pop : {}

                silent = options.delete(:silent).equal?(false) ? '' : 's'
                id     = args.shift
                id   &&= AgentProxy.id_from_agent_channel(id)
                raise ArgumentError, "Unrecognized Hash options to login(): #{options.inspect}" if options.any?
                raise ArgumentError, "Unrecognized argument to login(): #{args.inspect}" if args.any?

                proxy.environment.execute('AgentLogin', id, silent)
              end

              # Removes the current channel from this queue
              def logout!
                # TODO: DRY this up. Repeated in the AgentProxy...
                proxy.environment.execute 'RemoveQueueMember', proxy.name
                case proxy.environment.variable("RQMSTATUS")
                  when "REMOVED"     then true
                  when "NOTINQUEUE"  then false
                  when "NOSUCHQUEUE"
                    raise QueueDoesNotExistError.new(proxy.name)
                  else
                    raise "Unrecognized RQMSTATUS variable!"
                end
              end

              def each(&block)
                check_agent_cache!
                agents.each(&block)
              end

              def first
                check_agent_cache!
                agents.first
              end

              def last
                check_agent_cache!
                agents.last
              end

              def cached?
                @cached
              end

              def to_a
                check_agent_cache!
                @agents
              end

              private

              def check_agent_cache!
                if cached?
                  load_agents! unless agents
                else
                  load_agents!
                end
              end

              def load_agents!
                raw_data = proxy.environment.variable "QUEUE_MEMBER_LIST(#{proxy.name})"
                @agents = raw_data.split(',').map(&:strip).reject(&:empty?).map do |agent|
                  AgentProxy.new(agent, proxy)
                end
                @cached_count = @agents.size
              end

            end

            class AgentProxy

              SUPPORTED_METADATA_NAMES = %w[status password name mohclass exten channel] unless defined? SUPPORTED_METADATA_NAMES

              class << self
                def id_from_agent_channel(id)
                  id = id.to_s
                  id.starts_with?('Agent/') ? id[%r[^Agent/(.+)$],1] : id
                end
              end

              attr_reader :interface, :proxy, :queue_name, :id
              def initialize(interface, proxy)
                @interface  = interface
                @id         = self.class.id_from_agent_channel interface
                @proxy      = proxy
                @queue_name = proxy.name
              end

              def remove!
                proxy.environment.execute 'RemoveQueueMember', queue_name, interface
                case proxy.environment.variable("RQMSTATUS")
                  when "REMOVED"     then true
                  when "NOTINQUEUE"  then false
                  when "NOSUCHQUEUE"
                    raise QueueDoesNotExistError.new(queue_name)
                  else
                    raise "Unrecognized RQMSTATUS variable!"
                end
              end

              # Pauses the given agent for this queue only. If you wish to pause this agent
              # for all queues, pass in :everywhere => true. Returns true if the agent was
              # successfully paused and false if the agent was not found.
              def pause!(options={})
                everywhere = options.delete(:everywhere)
                args = [(everywhere ? nil : queue_name), interface]
                proxy.environment.execute('PauseQueueMember', *args)
                case proxy.environment.variable("PQMSTATUS")
                  when "PAUSED"   then true
                  when "NOTFOUND" then false
                  else
                    raise "Unrecognized PQMSTATUS value!"
                end
              end

              # Pauses the given agent for this queue only. If you wish to pause this agent
              # for all queues, pass in :everywhere => true. Returns true if the agent was
              # successfully paused and false if the agent was not found.
              def unpause!(options={})
                everywhere = options.delete(:everywhere)
                args = [(everywhere ? nil : queue_name), interface]
                proxy.environment.execute('UnpauseQueueMember', *args)
                case proxy.environment.variable("UPQMSTATUS")
                  when "UNPAUSED" then true
                  when "NOTFOUND" then false
                  else
                    raise "Unrecognized UPQMSTATUS value!"
                end
              end

              # Returns true/false depending on whether this agent is logged in.
              def logged_in?
                status == 'LOGGEDIN'
              end

              private

              def status
                agent_metadata 'status'
              end

              def agent_metadata(data_name)
                data_name = data_name.to_s.downcase
                raise ArgumentError, "unrecognized agent metadata name #{data_name}" unless SUPPORTED_METADATA_NAMES.include? data_name
                proxy.environment.variable "AGENT(#{id}:#{data_name})"
              end

            end

            class QueueDoesNotExistError < StandardError
              def initialize(queue_name)
                super "Queue #{queue_name} does not exist!"
              end
            end

          end

          module MenuDigitResponse
            def timed_out?
              eql? 0.chr
            end
          end

      end
    end
  end
end
