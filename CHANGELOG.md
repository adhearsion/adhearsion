# [develop](https://github.com/adhearsion/adhearsion)

# [2.0.0.rc4](https://github.com/adhearsion/adhearsion/compare/v2.0.0.rc3...v2.0.0.rc4) - [2012-03-30](https://rubygems.org/gems/adhearsion/versions/2.0.0.rc4)
  * Feature: `Call#execute_controller` now takes a post-execution callback (proc)
  * Feature: App generator now includes directory scaffolding for call controller specs and a sample `spec_helper.rb` which loads app config and the `lib/` directory
  * Bugfix: Calls should be hung up when router executed controllers complete, not after everything executed by `Call#execute_controller`
  * Bugfix: Deal with race conditions raising exceptions when hanging up calls after a controller executes
  * Bugfix: Updates to new dependency APIs
  * Bugfix: Ensure `Call::Hangup` exceptions are captured properly by the router and fix test synchronization

# [2.0.0.rc3](https://github.com/adhearsion/adhearsion/compare/v2.0.0.rc2...v2.0.0.rc3) - [2012-03-23](https://rubygems.org/gems/adhearsion/versions/2.0.0.rc3)
  * Bugfix/Change: `Adhearsion::Calls` (`Adhearsion.active_calls`) now exactly mirrors the Hash API
  * Bugfix: Fix mis-use of `PlaybackError` (wrong namespace)
  * Bugfix: Calls collection now correctly hangs up dead calls, and only genuine crashes
  * Bugfix: Logging of playback errors is more explicit

# [2.0.0.rc2](https://github.com/adhearsion/adhearsion/compare/v2.0.0.rc1...v2.0.0.rc2) - [2012-03-22](https://rubygems.org/gems/adhearsion/versions/2.0.0.rc2)
  * Bugfix: Exceptions raised in call event handlers no longer kill the call actor
  * Bugfix: More exceptions handled internally by Adhearsion are logged in an appropriate context
  * Bugfix/Change: `Adhearsion::Calls` (`Adhearsion.active_calls`) is now an actor for better thread-safety, and mirrors the Hash API more closely.
  * Bugfix: Calls are now removed from the active call collection and hung up if their actor dies
  * Bugfix: SimonGame now works using the new `CallController#ask` api

# [2.0.0.rc1](https://github.com/adhearsion/adhearsion/compare/v2.0.0.beta1...v2.0.0.rc1) - [2012-03-20](https://rubygems.org/gems/adhearsion/versions/2.0.0.rc1)
  * Change: `CallController#join` now blocks until a corresponding unjoined event is received
  * Change: `CallController#speak` is now `CallController#say`
  * Change: `CallController#input` has been removed in favour of `#ask`

  * Feature: `CallController#menu` may now disallow the caller from interrupting prompts by specifying `:interruptible => false`
  * Feature: `CallController#menu` and `CallController#ask` returns a `Result` object from which the status and response may be established
  * Feature: `CallController#ask` behaves similarly to `#menu`, processing prompts and supporting `:terminator` and `:limit` options
  * Feature: Added `Call#unjoin`
  * Feature: `CallControll#join` now blocks until the corresponding call is unjoined and can be made non-blocking by passing `:async => true`
  * Feature: `CallController#dial` now supports overriding or extra options for each call destinations
  * Feature: Asterisk AMI events may now be handled using the `ami` handler
  * Feature: Added environment debugging info when running at trace level, and by using `rake debugging`

  * Bugfix: `ahn restart` now does not fail if the PID file is not found
  * Bugfix: AHN_ENV and RAILS_ENV are now respected correctly
  * Bugfix: `ahn` command now elminates all version mis-matches between installed and bundled gems
  * Bugfix: Adhearsion is now ruby warning-free
  * Bugfix: A hangup exception is now raised if call commands fail with a call-not-found
  * Bugfix: `CallController#record` now functions as advertised
  * Bugfix: The punchblock JID resource is not overriden if defined in config
  * Bugfix: `DialStatus` objects returned from `CallController#dial` now include the cases where dials fail
  * Bugfix: Calls are now processed after Punchblock reconnects
  * Bugfix: Better exception logging
  * Bugfix: Strings passed to `CallController#play` which contain `/` but are not file paths are now rendered as text
  * Bugfix: Adhearsion now functions correctly on Heroku
  * Cleaned up log messages

# [2.0.0.beta1](https://github.com/adhearsion/adhearsion/compare/v2.0.0.alpha3...v2.0.0.beta1) - [2012-03-07](https://rubygems.org/gems/adhearsion/versions/2.0.0.beta1)
  * Bugfix: #speak now correctly casts the argument to string if it is not SSML
  * Bugfix: The console pauses controllers on a call while taking control
  * Feature: Reopen logfiles on SIGHUP
  * Feature: Toggle :trace logging on SIGALRM (useful for debugging a live process)
  * Feature: It is now possible to execute a global component (using `Adhearsion::PunchblockPlugin.execute_component`)
  * Feature: Now set XMPP JID resource to a concatenation of hostname and process ID for ID/debugging purposes
  * Feature: CallController#dial now returns a DialStatus object indicating the status of the dial command
  * Feature: Punchblock plugin can now configure the active media engine (mostly for use on Asterisk)
  * Bugfix: Fix forcing Adhearsion to stop with enough SIGTERM or CTRL+C

# [2.0.0.alpha3](https://github.com/adhearsion/adhearsion/compare/v2.0.0.alpha2...v2.0.0.alpha3) - [2012-02-21](https://rubygems.org/gems/adhearsion/versions/2.0.0.alpha3)
  * Feature: Add `ahn generate` command to allow invocation of generators
  * Feature: Add simple generator for call controllers
  * Feature: Add simple generator for plugins
  * Feature: Allow plugins to register their generator classes
  * Feature: Add log level helper methods to Console
  * Feature: Console's shutdown/exit method initiates the shutdown routine
  * Bugfix: Remove config option for auto-accept - hard-coded to true
  * Bugfix: AHN_ENV and RAILS_ENV now do not interfere with each other when both are set, and ahn will boot in the RAILS_ENV if AHN_ENV is not set
  * Feature: The console can take control of a call
  * Bugfix: CallController#dial now blocks until all outbound calls complete
  * Bugfix: Call commands timing out now raise a timeout exception in the caller, but do not crash the actor
  * Feature: It is now possible to pause/resume call controllers
  * Bugfix: CallController#dial now unblocks immediately if the original call ends
  * Bugfix: CallController#dial now unblocks when the connected outbound call unjoins, rather than ending, incase post-processing on the outbound call is required
  * Bugfix: CallController#dial now hangs up outbound legs when it unblocks
  * Feature: CallController#dial now defaults the outbound caller ID to that of the controller's call
  * Change: The command to take control of a call is now 'take' rather than 'use'. 'take' called without a call ID present a list of currently running calls

# [2.0.0.alpha2](https://github.com/adhearsion/adhearsion/compare/v2.0.0.alpha1...v2.0.0.alpha2) - [2012-01-30](https://rubygems.org/gems/adhearsion/versions/2.0.0.alpha2)
  * Change: Plugins no longer load dialplan/event/rpc/console methods using corresponding class methods
  * Feature: CallController and Console can have modules of methods mixed in using `CallController.mixin` and `Console.mixin`
  * Feature: Added the ability to override configuration using environment variables. The correct names are given when running `rake adhearsion:config:show`, and are automatically added for all plugins. Plugins may define how the string environment variable is transformed to be useful.
  * Feature: Rake task adhearsion:config:show improved to make the output copy and paste-able in a configuration file.
  * Feature: Call variables are aggregated from the headers sent and received during its existence
  * Feature: Call variables are accessible using `#[]` and `#[]=` on the call
  * Feature: Router can match against variables on a call using `#[]`
  * Feature: adhearsion process is named via configuration module
  * Feature: CallController#dial now takes a `:for` (or `:timeout`) option to specify a timeout on the dial command
  * Feature: Include a sensible `.gitignore` in generated apps
  * Feature: CallController can now perform join operations on calls, and take either a call ID, a call object or a mixer name as the target
  * Bugfix: `Call` and `OutboundCall` now respond to `#to` and `#from` with the correct values from the offer/dial
  * Bugfix: An `OutboundCall` allows storing call variables just like a `Call`
  * Bugfix: The console should be shut down when shutting down the process
  * Rake tasks cleaned up and some initialization bugs fixed

# [2.0.0.alpha1](https://github.com/adhearsion/adhearsion/compare/v1.2.1...v2.0.0.alpha1) - [2012-01-17](https://rubygems.org/gems/adhearsion/versions/2.0.0.alpha1)

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

## Configuration
  * New configuration mechanism based on Loquacious that allows to configure both Adhearsion platform and plugins
  * Added rake tasks to check the config options (rake adhearsion:config:desc) and config values (rake adhearsion:config:values)
  * `automatically_answer_incoming_calls` has been replaced with `automatically_accept_incoming_calls`, which when set to `true` (as is the default), will automatically indicate call progress to the 3rd party, causing ringing. `answer` must now be used explicitly in the dialplan.
  * Adhearsion now has environments. By default these are development, production, staging, test, and the set can be extended. The environment in use is dictated by the value of the AHN_ENV environment variable. Config may be set per environment.

## Dialplan changes
  * The dialplan no longer responds to methods for retrieval of call variables. This is because variables are aggregated from several sources, including SIP headers, which could result in collisions with methods that are required in the dialplan/controllers.

### Media output
  * Output functions reworked to to take advantage of Punchblock features, though method signatures have been kept similar.
  * Output now allows for usage of String, Numeric, Time/Date, files on disk, files served via HTTP, and direct SSML. All non-file types are played via TTS.
  * Output types are automatically detected and played accordingly

### Input (DTMF and ASR)
  * The same output types and recognition are now used in the input prompts too
  * Input currently is DTMF-only using the `#input`, `#wait_for_digit` and `#stream_file` methods compatibly with preceding versions

### Menu system
  * #menu method and related code completely rewritten to take advantage of the new controller functionality and streamline the DSL.
  * The #menu block now uses #match instead of #link, and allows for blocks as match actions
  * #menu now resumes execution inside the current controller after completion

### Recording
  * TODO

### Conferencing
  * TODO

### Bridging
  * TODO

### Call routing & controllers
  * To be platform agnostic, inbound calls are no longer routed by Asterisk context. There is now an inbound call routing DSL defined in config/adhearsion.rb which routes calls based on their parameters to either a controller class or specifies a dialplan in a block.
  * Call controllers (classes which inherit from Adhearsion::CallController) are the mechanism by which complex applications should be written. A controller is instantiated per call, and must respond to #run. Controllers have many "dialplan" methods, the same as dialplan.rb did.
  * dialplan.rb is removed and no longer used. These should be moved to the router.

## Eventing system
  * Removed Theatre
  * Event namespaces no longer need to be registered, and events with any name may be triggered and handled.
  * The DSL has been simplified. For example, AMI events may now be handled like:

  ```ruby
  asterisk_manager_interface do |event|
    ...
  end

  asterisk_manager_interface :name => /NewChannel/ do |event|
    ...
  end
  ```

## Logging
  * Switched logging mechanism from log4r to logging
  * Any logging config value can be updated via the centralized configuration object
  * 6 logging levels are supported by default: TRACE < DEBUG < INFO < WARN < ERROR < FATAL
  * The default logging pattern outputs the class name in any log message, using a colorized pattern in STDOUT to improve readability
  * Any log message from an Adhearsion::Call object outputs the call unique id to distinguish messages from any call
  * Log file location is configurable

## Removal of non-core-critical functionality
  * Removed all asterisk specific functionality
    FIXME: What functionality?
    * ConfirmationManager
    * Asterisk AGI/AMI connection/protocol related code
    * Asterisk `h` extension handling
  * Removed LDAP, XMPP, Rails, ActiveRecord and DRb functionality and replaced them with plugins.
  * Extracted some generic code to dependencies:
    * future-resource

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
  * Defined some project management guidelines for Adhearsion core (see http://adhearsion.com/contribute).
  * TODO: Defined an Adhearsion code style guide and implemented it across the codebase (see http://adhearsion.com/style-guide).
  * TODO: Transferred copyright in the Adhearsion codebase from individual contributors to Adhearsion Foundation Inc, the non-profit organisation responsible for supporting the Adhearsion project.
  * TODO: Dual-licensed as LGPL and MIT.

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
