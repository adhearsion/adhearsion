
require 'adhearsion/voip/menu_state_machine/menu_class'

module Adhearsion
  module VoIP
    module Asterisk
      module Commands 
        
        RESPONSE_PREFIX = "200 result=" unless defined? RESPONSE_PREFIX
        
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
          :blind_transfer => lambda do
            variable "TRANSFER_CONTEXT" => options[:context] if options && options.has_key?(:context)
            extend_dynamic_features_with 'blindxfer'
          end
        } unless defined? DYNAMIC_FEATURE_EXTENSIONS
        
	# Utility method to write to pbx.
        def write(message) 
          to_pbx.print(message)
        end
        
	# Utility method to read from pbx. Hangup if nil.
        def read 
          returning from_pbx.gets do |message|
            raise Hangup if message.nil?
            ahn_log.agi.debug "<<< #{message}"
          end
        end
        
        # This method is the underlying method executed by nearly all the command methods in this module.
        # It is used to send the plaintext commands in the proper AGI format over TCP/IP back to an Asterisk server via the
        # FAGI protocol.
        # It is not recommended that you call this method directly unless you plan to write a new command method
        # in which case use this method you to communicate directly with an Asterisk server via the FAGI protocol.
        # @see http://www.voip-info.org/wiki/view/Asterisk+FastAGI More information about FAGI
        def raw_response(message = nil)
          ahn_log.agi.debug ">>> #{message}"
          write message if message
          read
        end
        
        # The answer command must be called first before any other commands can be issued.
        # In typical adhearsion applications the answer command is called by default as soon
        # as a call is transfered to a valid context in dialplan.rb.
        # If you do not want your adhearsion application to automatically issue an answer command,
        # then you must edit your startup.rb file and configure this setting.
        # Keep in mind that you should not need to issue another answer command after 
        # an answer command has already been issued either explicitly by your code or implicitly
        # by the standard adhearsion configuration.
        def answer
          raw_response "ANSWER"
          true
        end
        
        # This asterisk dialplan command allows you to instruct Asterisk to start applications
        # which are typically run from extensions.conf.
        #
        # The most common commands are already made available through the FAGI interface provided
        # by this code base.  For commands that do not fall into this category, then exec is what you
        # should use.
        #
        # For example, if there are specific asterisk modules you have loaded that will not 
        # available through the standard commands provided through FAGI - then you can used EXEC.
        #
        # @example Using execute in this way will add a header to an existing SIP call.
        #   execute 'SIPAddHeader', '"Call-Info: answer-after=0"
        # 
        # @see http://www.voip-info.org/wiki/view/Asterisk+-+documentation+of+application+commands Asterisk Dialplan Commands
        def execute(application, *arguments)
          result = raw_response("EXEC #{application} \"#{arguments * '","'}\"")
          return false if error?(result)
          result
        end

        # Sends a message to the console via the verbose message system.
        # @example Use this command to inform someone watching the Asterisk console
        # of actions happening within Adhearsion.
        #   verbose 'Processing call with Adhearsion' 3
        #
        # @see http://www.voip-info.org/wiki/view/verbose
        def verbose(message, level = nil)
            result = raw_response("VERBOSE \"#{message}\" #{level}")
            return false if error?(result)
            result
        end
        
        # Hangs up the current channel. After this command is issued, you will not be able to send any more AGI
        # commands but the dialplan Thread will still continue, allowing you to do any post-call work.
        #
        def hangup
          raw_response 'HANGUP'
        end
        
        # Plays the specified sound file names. This method will handle Time/DateTime objects (e.g. Time.now),
        # Fixnums (e.g. 1000), Strings which are valid Fixnums (e.g "123"), and direct sound files. When playing
        # numbers, Adhearsion assumes you're saying the number, not the digits. For example, play("100")
        # is pronounced as "one hundred" instead of "one zero zero".
        #
        # Note: it's not necessary to supply a sound file extension; Asterisk will try to find a sound
        # file encoded using the current channel's codec, if one exists. If not, it will transcode from
        # the default codec (GSM). Asterisk stores its sound files in /var/lib/asterisk/sounds.
        #
        # @example Play file hello-world.???
        #   play 'hello-world'
	# @example Speak current time
        #   play Time.now
	# @example Play sound file, speak number, play two more sound files
        #   play %w"a-connect-charge-of 22 cents-per-minute will-apply"
	# @example Play two sound files
        #   play "you-sound-cute", "what-are-you-wearing"
        #
        def play(*arguments)
          arguments.flatten.each do |argument|
            play_time(argument) || play_numeric(argument) || play_string(argument)
          end
        end

        # Records a sound file with the given name. If no filename is specified a file named by Asterisk
        # will be created and returned. Else the given filename will be returned. If a relative path is
        # given, the file will be saved in the default Asterisk sound directory, /var/lib/spool/asterisk
        # by default.
        #
        # Silence and maxduration is specified in seconds.
        #
        # @example Asterisk generated filename
        #   filename = record
        # @example Specified filename
        #   record '/path/to/my-file.gsm'
        # @example All options specified
        #   record 'my-file.gsm', :silence => 5, :maxduration => 120
        #
        def record(*args)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          filename = args.shift || "/tmp/recording_%d.gsm"
          silence     = options.delete(:silence) || 0
          maxduration = options.delete(:maxduration) || 0

          execute("Record", filename, silence, maxduration)

          # If the user hangs up before the recording is entered, -1 is returned and RECORDED_FILE
          # will not contain the name of the file, even though it IS in fact recorded.
          filename.index("%d") ? get_variable('RECORDED_FILE') : filename
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

        # Menu creates an interactive menu for the caller.
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
        #   | exact matches |	potential matches	| result                                               |
        #   |---------------|-------------------|------------------------------------------------------|
        #   |  0	          |  0	               | Fail and start over                                  |
        #   |  1	          |  0	               | Match found!                                         |
        #   |  0	          | >0	               | Get another digit                                    |
        #   | >1	          |  0	               | Go with the first exact match                        |
        #   |  1	          | >0	               | Get another digit. If timeout, use exact match       |
        #   | >1	          | >0	               | Get another digit. If timeout, use first exact match |
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
        
        # This method is used to receive keypad input from the user. Digits are collected
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
      	# 
      	# When specifying files to play, the playback of the sequence of files will stop
      	# immediately when the user presses the first digit.
      	#
      	# The :timeout option works like a digit timeout, therefore each digit pressed
      	# causes the timer to reset. This is a much more user-friendly approach than an
        # absolute timeout.
      	#
      	# Note that when you don't specify a digit limit, the :accept_key becomes "#"
      	# because there'd be no other way to end the collection of digits. You can
      	# obviously override this by passing in a new key with :accept_key.
        def input(*args)
          options = args.last.kind_of?(Hash) ? args.pop : {}
          number_of_digits = args.shift
          
          sound_files     = Array options.delete(:play)
          timeout         = options.delete(:timeout)
          terminating_key = options.delete(:accept_key)
          terminating_key = if terminating_key
            terminating_key.to_s
          elsif number_of_digits.nil? && !terminating_key.equal?(false)
            '#'
          end
          
          if number_of_digits && number_of_digits < 0
            ahn_log.agi.warn "Giving -1 to input() is now deprecated. Don't specify a first " +
                             "argument to simulate unlimited digits." if number_of_digits == -1
            raise ArgumentError, "The number of digits must be positive!"
          end
          
          buffer = ''
          key = sound_files.any? ? interruptible_play(*sound_files) || '' : wait_for_digit(timeout || -1)
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
          raise Adhearsion::VoIP::DSL::Dialplan::ContextNotFoundException unless context.kind_of?(Adhearsion::DialPlan::DialplanContextProc)
          
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
      	
      	# The queue method puts a call into a call queue to be answered by an agent registered with that queue.
      	# The queue method takes a queue_name as an argument to place the caller in the appropriate queue.
	# @see http://www.voip-info.org/wiki-Asterisk+cmd+Queue Full information on the Asterisk Queue
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

        # Returns true if your last call to dial() finished with the ANSWER state, as reported
        # by Asterisk. Returns false otherwise
        def last_dial_successful?
          last_dial_status == :answered
        end

        # Opposite of last_dial_successful?()
        def last_dial_unsuccessful?
          not last_dial_successful?
        end
        
        # This feature is presently experimental! Do not use it!
        def speak(text, engine=:none)
          engine = Adhearsion::Configuration::AsteriskConfiguration.speech_engine || engine
          execute SpeechEngines.send(engine, text)
        end
        
        # This method is a high-level way of enabling features you create/uncomment from features.conf.
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
        def disable_feature(feature_name)
          enabled_features_variable = variable 'DYNAMIC_FEATURES'
          enabled_features = enabled_features_variable.split('#')
          if enabled_features.include? feature_name
            enabled_features.delete feature_name
            variable 'DYNAMIC_FEATURES' => enabled_features.join('#')
          end
        end
        
        # Used to join a particular conference with the MeetMe application. To
        # use MeetMe, be sure you have a proper timing device configured on your
        # Asterisk box. MeetMe is Asterisk's built-in conferencing program.
        # @see http://www.voip-info.org/wiki-Asterisk+cmd+MeetMe Asterisk Meetme Application Information
        def join(conference_id, options={})
          conference_id = conference_id.to_s.scan(/\w/).join
          command_flags = options[:options].to_s # This is a passthrough string straight to Asterisk
          pin = options[:pin]
          raise ArgumentError, "A conference PIN number must be numerical!" if pin && pin.to_s !~ /^\d+$/
          # The 'd' option of MeetMe creates conferences dynamically.
          command_flags += 'd' unless command_flags.include? 'd'
          
          execute "MeetMe", conference_id, command_flags, options[:pin]
        end
        
        # Issue this command to access a channel variable that exists in the asterisk dialplan (i.e. extensions.conf)
        # Use get_variable to pass information from other modules or high level configurations from the asterisk dialplan
        # to the adhearsion dialplan.
	# @see: http://www.voip-info.org/wiki/view/get+variable Asterisk Get Variable
      	def get_variable(variable_name)
      	  result = raw_response("GET VARIABLE #{variable_name}")
      	  case result
      	    when "200 result=0"
      	      return nil
    	      when /^200 result=1 \((.*)\)$/
    	        return $LAST_PAREN_MATCH
    	    end
    	  end
    	  
    	  # Use set_variable to pass information back to the asterisk dial plan.
    	  # Keep in mind that the variables are not global variables.  These variables only exist for the channel
    	  # related to the call that is being serviced by the particular instance of your adhearsion application.
    	  # You will not be able to pass information back to the asterisk dialplan for other instances of your adhearsion
    	  # application to share.  Once the channel is "hungup" then the variables are cleared and their information is gone.
    	  # @see http://www.voip-info.org/wiki/view/set+variable Asterisk Set Variable
    	  def set_variable(variable_name, value)
    	    raw_response("SET VARIABLE %s %p" % [variable_name.to_s, value.to_s]) == "200 result=1"
  	    end
    	  
    	  # The variable method allows you to either set or get a channel variable from Asterisk
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
    	  
    	  # Use the voicemail method to send a caller to a voicemail box to leave a message. 
    	  # @see http://www.voip-info.org/tiki-index.php?page=Asterisk+cmd+VoiceMail Asterisk Voicemail
    	  # The method takes the mailbox_number of the user to leave a message for and a
    	  # greeting_option that will determine which message gets played to the caller.
        def voicemail(*args)
          options_hash    = args.last.kind_of?(Hash) ? args.pop : {}
          mailbox_number  = args.shift
          greeting_option = options_hash.delete(:greeting)
          skip_option     = options_hash.delete(:skip)
          raise ArgumentError, 'You supplied too many arguments!' if mailbox_number && options_hash.any?
          greeting_option = case greeting_option
            when :busy: 'b'
            when :unavailable: 'u'
            when nil: nil
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
            when 'SUCCESS': true
            when 'USEREXIT': false
            else nil
          end
        end
        
        # The voicemail_main method puts a caller into the voicemail system to fetch their voicemail
        # or set options for their voicemail box.
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
        
        # Use this command to dial an extension or "phone number" in asterisk.
        # This command maps to the Asterisk DIAL command in the asterisk dialplan. 
        #
        # The first parameter, number, must be a string that represents the extension or "number" that asterisk should dial.
        # Be careful to not just specify a number like 5001, 9095551001
        # You must specify a properly formatted string as Asterisk would expect to use in order to understand
        # whether the call should be dialed using SIP, IAX, or some other means.
        #
        # Options Parameter:
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
      	def say_digits(digits)
      	  execute "saydigits", validate_digits(digits)
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
        
        #
        # This will play a sequence of files, stopping the playback if a digit is pressed. If a digit is pressed, it will be
        # returned as a String. If the files played with no keypad input, nil will be returned.
        #
        def interruptible_play(*files)
          files.flatten.each do |file|
            result = result_digit_from raw_response("STREAM FILE #{file} 1234567890*#")
            return result if result != 0.chr
          end
          nil
        end

        protected
        
          # wait_for_digits waits for the input of digits based on the number of milliseconds
          def wait_for_digit(timeout=-1)
            timeout *= 1_000 if timeout != -1
            result = result_digit_from raw_response("WAIT FOR DIGIT #{timeout.to_i}")
            (result == 0.chr) ? nil : result
          end
        
          ##
          # Deprecated name of interruptible_play(). This is a misspelling!
          #
          def interruptable_play(*files)
            ahn_log.deprecation.warn 'Please change your code to use interruptible_play() instead. "interruptable" is a misspelling! interruptable_play() will work for now but will be deprecated in the future!'
            interruptible_play(*files)
          end
          
          # set_callier_id_number method allows setting of the callerid number of the call
          def set_caller_id_number(caller_id)
            return unless caller_id
            raise ArgumentError, "Caller ID must be numerical" if caller_id.to_s !~ /^\d+$/
            raw_response %(SET CALLERID %p) % caller_id
          end
          
          # set_caller_id_name method allows the setting of the callerid name of the call
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
            returning digits.to_s do |digits_as_string|
              raise ArgumentError, "Can only be called with valid digits!" unless digits_as_string =~ /^[0-9*#-]+$/
            end
          end
          
          def error?(result)
            result.to_s[/^#{response_prefix}(?:-\d+|0)/]
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

                raise ArgumentError, "Unrecognized args to join!: #{options.inspect}" if options.any?

                ring_style = case ring_style
                  when :ringing: 'r'
                  when :music:   ''
                  when nil
                  else bad_argument[:play => ring_style]
                end.to_s
                
                allow_hangup = case allow_hangup
                  when :caller:   'H'
                  when :agent:    'h'
                  when :everyone: 'Hh'
                  when nil
                  else bad_argument[:allow_hangup => allow_hangup]
                end.to_s
                
                allow_transfer = case allow_transfer
                  when :caller:   'T'
                  when :agent:    't'
                  when :everyone: 'Tt'
                  when nil
                  else bad_argument[:allow_transfer => allow_transfer]
                end.to_s
                
                terse_character_options = ring_style + allow_transfer + allow_hangup
                
                [terse_character_options, '', announcement, timeout].map(&:to_s)
              end

            end
            
            attr_reader :name, :environment
            def initialize(name, environment)
              @name, @environment = name, environment
            end
            
            # Makes the current channel join the queue. Below are explanations of the recognized Hash-key
            # arguments supported by this method.
            #
            #   :timeout        - The number of seconds to wait for an agent to answer
            #   :play           - Can be :ringing or :music.
            #   :announce       - A sound file to play instead of the normal queue announcement.
            #   :allow_transfer - Can be :caller, :agent, or :everyone. Allow someone to transfer the call.
            #   :allow_hangup   - Can be :caller, :agent, or :everyone. Allow someone to hangup with the * key.
            # 
            # Usage examples:
            # 
            #  - queue('sales').join!
            #  - queue('sales').join! :timeout => 1.minute
            #  - queue('sales').join! :play => :music
            #  - queue('sales').join! :play => :ringing
            #  - queue('sales').join! :announce => "custom/special-queue-announcement"
            #  - queue('sales').join! :allow_transfer => :caller
            #  - queue('sales').join! :allow_transfer => :agent
            #  - queue('sales').join! :allow_hangup   => :caller
            #  - queue('sales').join! :allow_hangup   => :agent
            #  - queue('sales').join! :allow_hangup   => :everyone
            #  - queue('sales').join! :allow_transfer => :agent, :timeout => 30.seconds, 
            def join!(options={})
              environment.execute("queue", name, *self.class.format_join_hash_key_arguments(options))
          	  normalize_queue_status_variable environment.variable("QUEUESTATUS")
            end
            
            def agents(options={})
              cached = options.has_key?(:cache) ? options.delete(:cache) : true
              raise ArgumentError, "Unrecognized arguments to agents(): #{options.inspect}" if options.keys.any?
              if cached
                @cached_proxy ||= QueueAgentsListProxy.new(self, true)
              else
                @uncached_proxy ||=  QueueAgentsListProxy.new(self, false)
              end
            end
            
            def waiting_count
              raise QueueDoesNotExistError.new(name) unless exists?
              environment.variable("QUEUE_WAITING_COUNT(#{name})").to_i
            end
            
            def empty?
              waiting_count == 0
            end
            
            def any?
              waiting_count > 0
            end
            
            def exists?
              environment.execute('RemoveQueueMember', name, 'SIP/AdhearsionQueueExistenceCheck')
              environment.variable("RQMSTATUS") != 'NOSUCHQUEUE'
            end
            
            private
            
            def normalize_queue_status_variable(variable)
              returning variable.downcase.to_sym do |queue_status|
                raise QueueDoesNotExistError.new(name) if queue_status == :unknown
              end
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
              
              # Supported Hash-key arguments are :penalty and :name. The :name value will be viewable in
              # the queue_log. The :penalty is the penalty assigned to this agent for answering calls on
              # this queue
              def new(*args)
                
                options   = args.last.kind_of?(Hash) ? args.pop : {}
                interface = args.shift || ''
                
                raise ArgumentError, "You may only supply an interface and a Hash argument!" if args.any?
                
                penalty = options.delete(:penalty) || ''
                name    = options.delete(:name)    || ''
                
                raise ArgumentError, "Unrecognized argument(s): #{options.inspect}" if options.any?
                
                proxy.environment.execute("AddQueueMember", proxy.name, interface, penalty, '', name)
                
                case proxy.environment.variable("AQMSTATUS")
                  when "ADDED"         : true
                  when "MEMBERALREADY" : false
                  when "NOSUCHQUEUE"   : raise QueueDoesNotExistError.new(proxy.name)
                  else
                    raise "UNRECOGNIZED AQMSTATUS VALUE!"
                end
                
                # TODO: THIS SHOULD RETURN AN AGENT INSTANCE
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
                  when "REMOVED"     : true
                  when "NOTINQUEUE"  : false
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
                  when "REMOVED"     : true
                  when "NOTINQUEUE"  : false
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
                  when "PAUSED"   : true
                  when "NOTFOUND" : false
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
                  when "UNPAUSED" : true
                  when "NOTFOUND" : false
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
            
            class QueueDoesNotExistError < Exception
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
