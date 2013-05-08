# [develop](https://github.com/adhearsion/adhearsion)

# [2.3.3](https://github.com/adhearsion/adhearsion/compare/v2.3.2...v2.3.3) - [2013-05-08](https://rubygems.org/gems/adhearsion/versions/2.3.3)
  * Bugfix: Support Celluloid 0.14's new block semantics

# [2.3.2](https://github.com/adhearsion/adhearsion/compare/v2.3.1...v2.3.2) - [2013-05-03](https://rubygems.org/gems/adhearsion/versions/2.3.2)
  * Bugfix: Correctly register readiness to handle calls with VoIP platform.
  * Bugfix: Don't raise when the router tries to clear up after a CallController which outlived its Call actor.
  * Bugfix: Don't share metadata between all controllers invoked by a route. This was causing concurrent mutation bugs and all sorts of weirdness.
  * Bugfix: Ensure that a CallController can still log safely even if its Call (and therefore scoped logger) is gone.
  * Bugfix: Fix some spec false positives and failures due to dependency changes.

# [2.3.1](https://github.com/adhearsion/adhearsion/compare/v2.3.0...v2.3.1) - [2013-03-28](https://rubygems.org/gems/adhearsion/versions/2.3.1)
  * Bugfix: Fix a leftover Celluloid deprecation warning

# [2.3.0](https://github.com/adhearsion/adhearsion/compare/v2.2.1...v2.3.0) - [2013-03-25](https://rubygems.org/gems/adhearsion/versions/2.3.0)
  * Feature: Allow specifying a renderer per invocation of `#menu`, `#interruptible_play`, `#ask`, `#play` and `#play!`

    ```ruby
    play 'tt-monkeys', renderer: :native
    ```

  * Feature: Make it possible to disable punchblock connection by way of settings
  * Feature: Allow specifying exact input digits to recognize for interrupting a recording
  * Bugfix: Run input validations before length check so we always return the more appropriate response
  * Bugfix: Plugin initializers now run in the context of the plugin class, not nil
  * Bugfix: Write PID without race conditions (#266)
  * CS: Prevent Celluloid deprecation warnings

# [2.2.1](https://github.com/adhearsion/adhearsion/compare/v2.2.0...v2.2.1) - [2013-01-06](https://rubygems.org/gems/adhearsion/versions/2.2.1)
  * Bugfix: No longer crash logging randomly
  * Bugfix: Correctly route outbound calls
  * Bugfix: Handle calls when daemonized correctly
  * Bugfix: Test suites now pass on JRuby and Ruby 2.0.0

# [2.2.0](https://github.com/adhearsion/adhearsion/compare/v2.1.3...v2.2.0) - [2012-12-17](https://rubygems.org/gems/adhearsion/versions/2.2.0)
  * Feature: Statistics API providing counts of calls dialed, offered, rejected, routed and active

    ```ruby
    Adhearsion.statistics.dump # => #<Adhearsion::Statistics::Dump timestamp=2012-12-17 10:31:05 -0500, call_counts={:dialed=>0, :offered=>18, :routed=>6, :rejected=>0, :active=>0}, calls_by_route={"Sesame Street"=>3, "Mr. Rogers Neighborhood"=>2, "default"=>1}>
    ```
  * Feature: Accessor for peer calls when bridged

    ```ruby
    call.peers # => {"0f4h382j290k09k" => #<Adhearsion::Call ...>}
    ```
  * Feature: Allow specifying controller metadata when originating outbound calls

    ```ruby
    Adhearsion::OutboundCall.originate 'foo@bar.com', controller: FooBarController, controller_metadata: {foo: 'bar'}
    ```
  * Feature: Allow specifying confirmation controller metadata to `CallController#dial`

    ```ruby
    dial 'foo@bar.com', confirm: ConfirmationController, confirm_metadata: {foo: 'bar'}
    ```
  * Feature: Set default voice on output components when specified in config

    ```ruby
    config.punchblock.default_voice = 'kal'
    ```
  * Feature: Be more flexible about DTMF utterance parsing
  * Feature: Added specs for the SimonGame
  * Feature: Allow configuring the lifetime of a call object after hangup. This makes it possible to control the number of call objects (and therefore threads) in use by Adhearsion, by expiring them earlier or later than the 30 second default (as measured from the point at which the call disconnects).

    ```ruby
    config.platform.after_hangup_lifetime = 10
    ```
  * Feature: Support collections passed to `CallController#play`
    ```ruby
    recordings = ['one', 'two', 'three']
    play recordings
    ````
  * Feature: Support arrays passed to `#match` in a `CallController#menu`
    ```ruby
    possible_digits = [1,2,3,4]
    menu 'foobar' do
      match possible_digits, FooController
    end
    ```
  * Feature: Output document formatter for a call controller is now overridable
    ```ruby
    # Replacement formatter designed to render all TTS extra slow
    class MyFormatter < Adhearsion::CallController::Output::Formatter
      def ssml_for_text(argument, options = {})
        RubySpeech::SSML.draw do
          prosody rate: 'x-slow' do
            argument
          end
        end
      end
    end

    class MyController < Adhearsion::CallController
      def run
        speak "This will be sloooooow"
      end

      def output_formatter
        MyFormatter.new
      end
    end
    ```
  * Feature: Refactored recording functionality into a Recorder class for easier implementation of specific APIs
    ```ruby
    # Alternative #record implementation, returning the input component also
    def record(options = {})
      recorder = Recorder.new self, options

      recorder.handle_record_completion do |event|
        catching_standard_errors { yield event if block_given? }
      end

      recorder.run
      [recorder.record_component, recorder.stopper_component]
    end
    ```
  * Bugfix: Generate sane spec defaults for new apps and controllers
  * Bugfix: `CallController#record` now allows partial-second timeouts
  * Bugfix: Ensure calls are removed from the active collection when they terminate cleanly
  * Bugfix: Plug a big memory leak

# [2.1.3](https://github.com/adhearsion/adhearsion/compare/v2.1.2...v2.1.3) - [2012-10-11](https://rubygems.org/gems/adhearsion/versions/2.1.3)
  * Bugfix: Originating call is now answered before joining calls using `CallController#dial`
  * Bugfix: Output controller methods no longer falsely detect a string with a colon as a URI for an audio file
  * Bugfix: `CallController#record` takes timeout in seconds instead of milliseconds
  * Bugfix: Generating controllers given lower case names now works properly
  * Update: Bump Celluloid dependency
  * CS: Log when a controller is executed on a call

# [2.1.2](https://github.com/adhearsion/adhearsion/compare/v2.1.1...v2.1.2) - [2012-09-16](https://rubygems.org/gems/adhearsion/versions/2.1.2)
  * Bugfix: Celluloid 0.12.x dependency now disallowed due to incompatible API changes.
  * Bugfix: Generated Gemfiles no longer pessimistically locked. Matches promise of SemVer compliance.
  * Bugfix: Added missing API documentation for `Adhearsion::OutboundCall`.
  * Bugfix: Controller spec now includes a useful example.

# [2.1.1](https://github.com/adhearsion/adhearsion/compare/v2.1.0...v2.1.1) - [2012-09-05](https://rubygems.org/gems/adhearsion/versions/2.1.1)
  * Bugfix: #dial timeout now does not place an upper limit on the duration of a bridged call

# [2.1.0](https://github.com/adhearsion/adhearsion/compare/v2.0.1...v2.1.0) - [2012-08-07](https://rubygems.org/gems/adhearsion/versions/2.1.0)

## Features
  * Initial support for FreeSWITCH
  * Added the possibility to specify a confirmation controller on `#dial` operations
  * Allow specifying a controller to run when originating an outbound call
  * Allow `Call#execute_controller` to take a block instead of a controller instance. Simplifies event-based execution of simple controllers (eg whisper into a call)
  * Allow route modifiers such that they:
    * Do not accept calls that match
    * Do not execute a controller
    * Do not hangup after controller execution
  * Permit asynchronous output using bang version of methods (eg `CallController#play!`), returning an output component, which can be stopped
  * Added `CallController#safely` which will catch and log `StandardError` in a call controller, but will not allow it to crash the controller
  * `CallController#record` now has an `:interruptible` option that allows recording to be stopped by pressing any DTMF key
  * Added `Call#on_joined` and `Call#on_unjoined` for easily registering joined/unjoined handlers
  * `Adhearsion.root` and `Adhearsion.root=` are now available to return the root path to the application. `Adhearsion.ahn_root=` is deprecated
  * `Adhearsion.deprecated` added for internal use to clearly mark deprecated methods

## Bugfixes
  * All output methods will now raise `Adhearsion::CallController::Output::PlaybackError` when output fails, instead of failing silently
  * `CallController#hangup` now prevents further execution of the controller
  * Calls which do not match any routes are rejected with an error
  * Calls are not accepted until a matching route is found
  * Give sensible dependency defaults for generated plugins
  * Fixed mocha-fail in generated plugins
  * Plugins generated with a snake_case name did not have the appropriate constants camelized
  * `CallController#dial` no longer creates outbound calls if the dialing party hangs up before it executes
  * `CallController#ask` no longer loops on timeout
  * Correct default port for Asterisk

# [2.0.1](https://github.com/adhearsion/adhearsion/compare/v2.0.0...v2.0.1) - [2012-06-04](https://rubygems.org/gems/adhearsion/versions/2.0.1)
  * Bugfix: Avoid infinitely recursive exception handlers
  * Bugfix: Don't require rubygems where we don't need it
  * Bugfix: Patch method name conflict with new Celluloid release
  * Bugfix: Generated applications are now locked to Adhearsion major version
  * Bugfix: Ensure the `#logger` method is defined more robustly on all objects
  * Bugfix: Ensure actor (call) loggers are accessible outside the object
  * Cleanup: Remove old invalid rake tasks, improve some documentation

# [2.0.0](https://github.com/adhearsion/adhearsion/compare/v1.2.1...v2.0.0) - [2012-04-11](https://rubygems.org/gems/adhearsion/versions/2.0.0)

## Major architectural changes
  * Adhearsion is no longer a framework for creating Asterisk applications, and it does not know anything about the specifics of Asterisk. Adhearsion now makes use of the Punchblock library which abstracts features from common telephony engines. Supported engines are now:
    * Asterisk 1.8+
    * Voxeo Prism 11 w/ rayo-server
  * Adhearsion now makes use of libraries for advanced concurrency primitives such as Actors, meaning Adhearsion is no longer compatible with Ruby 1.8. Officially supported Ruby platforms are:
    * Ruby 1.9.2+ (YARV)
    * JRuby 1.6.5+ (in 1.9 mode)
    * Rubinius 2.0 (on release, in 1.9 mode)
  * The old components architecture has been deprecated in favour of `Adhearsion::Plugin` (further details below).
  * Theatre has been replaced in favour of a girl_friday and has-guarded-handlers based event queueing/handling system (further details below).
  * The dialplan.rb file has been removed and is replaced by the routing DSL.

## Plugin system
  * Plugin system is the way to extend Adhearsion framework and provides the easiest path to add new functionality, configuration or modify the initialization process.
  * Created Plugin infrastructure. Adhearsion::Plugin class allows to create dialplan, rpc, event and console methods, add initializers
  and create or update any configuration
  * Moved deprecated Adhearsion::Components behaviour to the dedicated gem adhearsion-components
  * Moved ami_remote component to adhearsion-asterisk plugin
  * Moved Rails integration to adhearsion-rails plugin as it is not an Adhearsion core feature
  * Moved Active Record integration to adhearsion-rails plugin
  * Moved XMPP integration to adhearsion-xmpp plugin
  * Moved DRb integration to adhearsion-drb plugin
  * Moved LDAP integration to adhearsion-ldap plugin
  * Translate STOMP gateway component to a plugin and remove the component generators entirely
  * Translate simon_game component to plugin
  * CallController and Console can have modules of methods mixed in using `CallController.mixin` and `Console.mixin`

## Configuration
  * New configuration mechanism based on Loquacious that allows to configure both Adhearsion platform and plugins
  * Added rake tasks to check the config options (rake adhearsion:config:desc) and config values (rake adhearsion:config:values)
  * `automatically_answer_incoming_calls` has been replaced with `automatically_accept_incoming_calls`, which when set to `true` (as is the default), will automatically indicate call progress to the 3rd party, causing ringing. `answer` must now be used explicitly in the dialplan.
  * Adhearsion now has environments. By default these are development, production, staging, test, and the set can be extended. The environment in use is dictated by the value of the AHN_ENV environment variable. Config may be set per environment.
  * Added the ability to override configuration using environment variables. The correct names are given when running `rake adhearsion:config:show`, and are automatically added for all plugins. Plugins may define how the string environment variable is transformed to be useful.
  * adhearsion process is named via configuration module

## Dialplan changes
  * The dialplan no longer responds to methods for retrieval of call variables. This is because variables are aggregated from several sources, including SIP headers, which could result in collisions with methods that are required in the dialplan/controllers.

### Media output
  * Output functions reworked to to take advantage of Punchblock features, though method signatures have been kept similar.
  * Output now allows for usage of String, Numeric, Time/Date, files on disk, files served via HTTP, and direct SSML. All non-file types are played via TTS.
  * Output types are automatically detected and played accordingly
  * `CallController#speak` is now `CallController#say`

### Ask
  * `CallController#input` has been removed in favour of `#ask`
  * `CallController#ask` returns a `Result` object from which the status and response may be established
  * `CallController#ask` processes prompts and gathers input until some termination event (terminator digit, digit limit or timeout)

### Menu system
  * #menu method and related code completely rewritten to take advantage of the new controller functionality and streamline the DSL.
  * The #menu block now uses #match instead of #link, and allows for blocks as match actions
  * #menu now resumes execution inside the current controller after completion

### Recording
  * A dual-mode #record method has been added to CallController allowing both blocking and non-blocking recording

### Call Joining
  * CallController supports joining of calls, or calls to mixers using #join
  * `CallController#dial` now supports overriding or extra options for each call destination
  * CallController#dial now returns a DialStatus object indicating the status of the dial command
  * CallController#dial now defaults the outbound caller ID to that of the controller's call

### Call routing & controllers
  * To be platform agnostic, inbound calls are no longer routed by Asterisk context. There is now an inbound call routing DSL defined in config/adhearsion.rb which routes calls based on their parameters to either a controller class or specifies a dialplan in a block.
  * Call controllers (classes which inherit from Adhearsion::CallController) are the mechanism by which complex applications should be written. A controller is instantiated per call, and must respond to #run. Controllers have many "dialplan" methods, the same as dialplan.rb did.
  * dialplan.rb is removed and no longer used. These should be moved to the router.

## Eventing system
  * Removed Theatre
  * Event namespaces no longer need to be registered, and events with any name may be triggered and handled.
  * The DSL has been simplified. See the generated config file for examples.

## Logging
  * Switched logging mechanism from log4r to logging
  * Any logging config value can be updated via the centralized configuration object
  * 6 logging levels are supported by default: TRACE < DEBUG < INFO < WARN < ERROR < FATAL
  * The default logging pattern outputs the class name in any log message, using a colorized pattern in STDOUT to improve readability
  * Any log message from an `Adhearsion::Call` object outputs the call unique id to distinguish messages from any call
  * Log file location is configurable

## Removal of non-core-critical functionality
  * Removed all asterisk specific functionality
    * ConfirmationManager
    * Asterisk AGI/AMI connection/protocol related code
    * Asterisk `h` extension handling
  * Removed LDAP, XMPP, Rails, ActiveRecord and DRb functionality and replaced them with plugins.
  * Extracted some generic code to dependencies:
    * future-resource
    * ruby_ami
    * punchblock

## Miscellaneous
  * Removed a lot of unused or unecessary code, including:
    * Outbound call routing DSL
    * FreeSWITCH support. This will be added to Punchblock at a later date.
  * Replaced the rubigen generators with Thor
  * New CLI command structure. Run `ahn` for details.
  * Advanced shutdown routine:
    * On first :shutdown, we flag the state internally. The intent is to shut down when the active calls count reaches 0, but otherwise operate normally.

    * On second :shutdown, we start rejecting new incoming calls. Existing calls will continue to process until completion. Shut down when active call count reaches 0.

    * On third :shutdown, send a Hangup to all active calls. Shut down when active call count reaches 0.

    * In addition, the process can be force-stopped, which simply closes the connection to the server (and any component connections as well).
  * `ahn` command now elminates all version mis-matches between installed and bundled gems
  * Adhearsion is now ruby warning-free
  * Reopen logfiles on SIGHUP
  * Toggle TRACE logging on SIGALRM (useful for debugging a live process)
  * `Adhearsion::Calls` (`Adhearsion.active_calls`) is now an actor for better thread-safety, and mirrors the Hash API exactly.
  * `ahn generate` command allows invocation of generators for call controllers, plugins or those provided by plugins
  * The command to take control of a call is now 'take' rather than 'use'. 'take' called without a call ID presents a list of currently running calls
  * Defined some project management guidelines for Adhearsion core (see http://adhearsion.com/contribute).
  * Transferred copyright in the Adhearsion codebase from individual contributors to Adhearsion Foundation Inc, the non-profit organisation responsible for supporting the Adhearsion project.
  * Re-licensed as MIT.

# 1.2.1 - 2011-09-21
  * Removed the restful_rpc component since it is now in a gem.
  * Allow overriding the path to a component in the testing framework so as to support new style components (lib/)
  * Added a GUID to the default recording filename to ensure uniqueness
  * `ECONNRESET` exceptions are now handled as a call hangup
  * Fixed escaping of TTS strings containing commas when used with Cepstral via `#speak`
  * Made logging exceptions the responsibility of the framework rather than the app, so that this may not be disabled

# 1.2.0 - 2011-08-14
  * New method: `#play_or_speak1 allows playback of an audio file with TTS fallback
  * `#input` now takes `:speak` as a hash for TTS prompt or fallback
  * New method: `#speak` provides abstracted TTS rendering for UniMRCP and Cepstral
  * Allow leading "+" in Caller ID (E.164 format)
  * Allow using `--pid-file` without "daemon" for JRuby
  * Allow passing a block to #input to enable caller to detect when enough digits are collected.
  * Fix some issues with starting apps outside of their directory, generally related to Bundler/gem environments
  * Allow configuration of logging outputters/formatters
  * Using `ahn_log` in a dialplan context or on a call object logs to the call's context, named after its unique identifier
  * New method: `#record_to_file` with more useful return values

# 1.1.1 - 2011-06-13
  * `Command#play` now returns `false` if audio failed to play
  * Added new commands (`#play!`, `#interruptible_play!`, `#input!`) which raise PlaybackError if audio fails to play

# 1.1.0 - 2011-05-29
  * Added interactive call control console: ahn start console <path>
  * Added centralized exception handler through eventing system
  * Support for using ahn_hoptoad to send Adhearsion exceptions to Hoptoad
  * `Adhearsion.active_calls` can now use hash syntax to find calls by ID
  * Added `Adhearsion::Calls#to_h`
  * Add a Monitor to synchronize access to an AGI connection

# 1.0.3 - 2011-05-05
  * Fix the `play()` command regression when passing an array of strings. This was breaking the SimonGame
  * Deprecate `ManagerInterface#send_action_asynchronously`

# 1.0.2 - 2011-04-09
  * Fix rcov Rake task
  * Add Ben Langfeld as an author (Thanks, Ben!)
  * Add "rake" as a runtime dependency
  * Remove usage of BEGIN blocks (for Rubinius; CS)

# 1.0.1 - 2010-02-22
 NOTE for Ruby 1.9 users: The behavior of Ruby 1.9 and case statements has changed
      in a way that renders NumericalString objects incompatible with
      case statements. The suggested workaround is to cast the NumericalString
      to a string and then compare. Example:

  ```ruby
    obj = NumericalString.new("0987")
    case obj.to_s
    when "0987" then true
    else false
    end

    # Or, if you need to ignore the leading zero:
    case obj.to_i
    when 987 then true
    else false
    end
  ```

  See https://adhearsion.lighthouseapp.com/projects/5871/tickets/127-ruby-19-and-numericalstring-comparisons-in-case-statements

  * Add `say_chars` command.
  * Add `say_phonetic` command.
  * Update `play_time` to accept format and timezone paramenters. This allows you to read back any particular section of the Time object. (i.e. Using `:format => 'IMp'` would result in "eleven twenty-three" being said.)
  * Update `play_time` to allow using Date objects.
  * `QueueAgentsListProxy#new` now returns an `AgentProxy` instance if the agent was added successfully.
  * Add `state_interface` parameter to `QueueAgentsListProxy#new`. This allows you to specify a separate interface to watch for state changes on. (i.e. Your agents log in with Local channel extensions, but you want to check their direct SIP exten for state.)
  * Fixed issue with `Queue#join!` that would raise a `QueueDoesNotExist` error if the call was completed successfully.
  * Add support for AGI script parameter to `Queue#join!`
  * Migrate unit tests to RSpec 2
  * New components now include RubyGems skeleton files
  * Fix support for setting Caller ID name on AGI `dial()` command
  * Generate new apps with Bundler support, including auto-requiring of all gems
  * Update component testing framework to RSpec 2.x and mock with rspec

# 1.0.0 - 2010-10-28
  * Fall back to using Asterisk's context if the AGI URI context is not found
  * Enable configuration of `:auto_reconnect` parameter for AMI
  * Replace all uses of `Object#returning` with `Object#tap`
  * Add support for loading Adhearsion components from RubyGems
  * Fix long-running AMI session parser failure bug (#72)
  * Support for Rails 3 (and ActiveSupport 3.0)

# 0.8.6 - 2010-09-03
  * Fix packaging problem so all files are publicly readable
  * Improve AMI reconnecting logic; add "connection refused" retry timer
  * AGI protocol improvements: parse the status code and response text

# 0.8.5 - 2010-08-24
  NOTE: If you are upgrading an Adhearsion application to 0.8.5, note the change
  to how request URIs are handled. With 0.8.4, the context name in Asterisk was
  required to match the Adhearsion context in dialplan.rb. Starting in 0.8.5 if
  an application path is passed in on the AGI URI, it will be preferred over the
  context name. For example:

  ```
  [stuff]
  exten => _X.,1,AGI(agi://localhost/myapp)
  ```

  AHN 0.8.4- will execute the "stuff" context in dialplan.rb
  AHN 0.8.5+ will execute the "myapp" context in dialplan.rb

  If you followed the documentation and did not specify an application path in
  the URI (eg. `agi://localhost`) you will not be impacted by this change.

  Other changes:
  * Added XMPP module and sample component. This allows you to easily write components which utilise a persistent XMPP connection maintained by Adhearsion
  * Prefer finding the dialplan.rb entry point by the AGI request URI instead of the calling context
  * Added `:use_static_conf` option for "meetme" to allow the use of disk-file-managed conferences
  * Logging object now shared with ActiveRecord and Blather
  * Fixed a longstanding bug where newlines were not sent after each AGI command
  * Fixed parsing of DBGet AMI command/response
  * Better shutdown handling/cleanup
  * Attempt to allow the AMI socket to reconnect if connection is lost
  * Improved support for Ruby 1.9
  * Numerous smaller bugs fixed. See: https://adhearsion.lighthouseapp.com/projects/5871-adhearsion/milestones/76510-085

# 0.8.4 - 2010-06-24
  * Add configurable argument delimiter for talking to Asterisk. This enables Adhearsion to support Asterisk versions 1.4 (and prior) as well as 1.6 (and later).
  * Fixed using ActiveRecord in Adhearsion components
  * Daemonizing no longer truncates the Adhearsion log file
  * Add support for using ActiveLdap
  * Misc improvements to support Asterisk 1.6 changes
  * Escape commands sent to Asterisk via AGI
  * Manager Events now work when daemonized

# 0.8.3 -
  * The `uniqueid` call channel variable available in dialplan.rb is now *always* a String
  * Renamed `interruptable_play` to `interruptible_play` and made `interruptible_play` public instead of protected.
  * Fixed an Asterisk Manager Interface parsing issue in which colons sometimes got stuck into the key name.
  * AGI "request" variable coercer will not blow up if no request is given. (Helps in testing with netcat/telnet)

# 0.8.2 -
  * When a call hangs up, Adhearsion will no longer show random exceptions (that were okay) and instead allows the user to rescue a Hangup exception.
  * `ManagerInterfaceResponse` now include()s DRbUndumped, allowing `send_action()` to be called directly over DRb.
  * Fixes an inconsequential bug when CTL-C'ing Adhearsion.

# 0.8.1 - 2009-01-29
  * The sandbox component now comes
  * Minor bug fixes

# 0.8.0 rev 2
  * Added a few non-critical files to the `.gemspec`. They were ignored

# Notes from before 0.8.0:
  * (NOTE: This is obviously not a comprehensive list of pre-0.8.0 work. 0.8.0 was a complete rewrite of the previous version)
  * Adding a deprecation warning about `Fixnum#digit` and `Fixnum#digits`
  * Removed the AMI class and replaced it with the ManagerInterface class.
  * The old AMI high-level instance methods are available in the new ManagerInterface class, but a deprecation warning will be logged each time they're used. When the SuperManager class is implemented, they'll be removed entirely.
  * Moved Theatre into Adhearsion's lib folder.
