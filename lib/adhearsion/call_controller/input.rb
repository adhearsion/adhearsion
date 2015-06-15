# encoding: utf-8

require 'adhearsion/call_controller/input/ask_grammar_builder'
require 'adhearsion/call_controller/input/prompt_builder'
require 'adhearsion/call_controller/input/menu_builder'

module Adhearsion
  class CallController
    module Input

      InputError = Class.new Adhearsion::Error

      #
      # Prompts for input, handling playback of prompts, DTMF grammar construction, and execution
      #
      # @example A basic DTMF digit collection:
      #   ask "Welcome, ", "/opt/sounds/menu-prompt.mp3",
      #       timeout: 10, terminator: '#', limit: 3
      #
      # The first arguments will be a list of sounds to play, as accepted by #play, including strings for TTS, Date and Time objects, and file paths.
      # :timeout, :terminator and :limit options may be specified to automatically construct a grammar, or grammars may be manually specified.
      #
      # @param [Object, Array<Object>] args A list of outputs to play, as accepted by #play
      # @param [Hash] options Options to modify the grammar
      # @option options [Boolean] :interruptible If the prompt should be interruptible or not. Defaults to true
      # @option options [Integer] :limit Digit limit (causes collection to cease after a specified number of digits have been collected)
      # @option options [Integer] :timeout Timeout in seconds before the first and between each input digit
      # @option options [String] :terminator Digit to terminate input
      # @option options [RubySpeech::GRXML::Grammar, Array<RubySpeech::GRXML::Grammar>] :grammar One of a collection of grammars to execute
      # @option options [String, Array<String>] :grammar_url One of a collection of URLs for grammars to execute
      # @option options [Hash] :input_options A hash of options passed directly to the Punchblock Input constructor. See
      # @option options [Hash] :output_options A hash of options passed directly to the Punchblock Output constructor
      #
      # @return [Result] a result object from which the details of the utterance may be established
      #
      # @see Output#play
      # @see http://rdoc.info/gems/punchblock/Punchblock/Component/Input.new Punchblock::Component::Input.new
      # @see http://rdoc.info/gems/punchblock/Punchblock/Component/Output.new Punchblock::Component::Output.new
      #
      def ask(*args)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        prompts = args.flatten.compact

        options[:grammar] || options[:grammar_url] || options[:limit] || options[:terminator] || raise(ArgumentError, "You must specify at least one of limit, terminator or grammar")

        grammars = AskGrammarBuilder.new(options).grammars

        output_document = prompts.empty? ? nil : output_formatter.ssml_for_collection(prompts)

        PromptBuilder.new(output_document, grammars, options).execute self
      end

      # Creates and manages a multiple choice menu driven by DTMF, handling playback of prompts,
      # invalid input, retries and timeouts, and final failures.
      #
      # @example A complete example of the method is as follows:
      #   menu "Welcome, ", "/opt/sounds/menu-prompt.mp3", tries: 2, timeout: 10 do
      #     match 1, OperatorController
      #
      #     match 10..19 do
      #       pass DirectController
      #     end
      #
      #     match 5, 6, 9 do |exten|
      #       play "The #{exten} extension is currently not active"
      #     end
      #
      #     match '7', OfficeController
      #
      #     invalid { play "Please choose a valid extension" }
      #     timeout { play "Input timed out, try again." }
      #     failure { pass OperatorController }
      #   end
      #
      # The first arguments will be a list of sounds to play, as accepted by #play, including strings for TTS, Date and Time objects, and file paths.
      # :tries and :timeout options respectively specify the number of tries before going into failure, and the timeout in seconds allowed on each digit input.
      # The most important part is the following block, which specifies how the menu will be constructed and handled.
      #
      # #match handles connecting an input pattern to a payload.
      # The pattern can be one or more of: an integer, a Range, a string, an Array of the possible single types.
      # Input is matched against patterns, and the first exact match has it's payload executed.
      # Matched input is passed in to the associated block, or to the controller through #options.
      #
      # Allowed payloads are the name of a controller class, in which case it is executed through its #run method, or a block, which is executed in the context of the current controller.
      #
      # #invalid has its associated block executed when the input does not possibly match any pattern.
      # #timeout's block is run when timeout expires before receiving any input
      # #failure runs its block when the maximum number of tries is reached without an input match.
      #
      # Execution of the current context resumes after #menu finishes. If you wish to jump to an entirely different controller, use #pass.
      # Menu will return :failed if failure was reached, or :done if a match was executed.
      #
      # @param [Object] args A list of outputs to play, as accepted by #play
      # @param [Hash] options Options to use for the menu
      # @option options [Integer] :tries Number of tries allowed before failure
      # @option options [Integer] :timeout Timeout in seconds before the first and between each input digit
      # @option options [Boolean] :interruptible If the prompt should be interruptible or not. Defaults to true
      # @option options [String, Symbol] :mode Input mode to accept. May be :voice or :dtmf.
      # @option options [Hash] :input_options A hash of options passed directly to the Punchblock Input constructor
      # @option options [Hash] :output_options A hash of options passed directly to the Punchblock Output constructor
      #
      # @return [Result] a result object from which the details of the utterance may be established
      #
      # @see Output#play
      # @see CallController#pass
      #
      def menu(*args, &block)
        raise ArgumentError, "You must specify a block to build the menu" unless block
        options = args.last.kind_of?(Hash) ? args.pop : {}
        prompts = args.flatten.compact

        menu_builder = MenuBuilder.new(options, &block)

        output_document = prompts.empty? ? nil : output_formatter.ssml_for_collection(prompts)

        menu_builder.execute output_document, self
      end
    end
  end
end
