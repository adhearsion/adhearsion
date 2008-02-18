require File.join(File.dirname(__FILE__), 'config_generator')

module Adhearsion
  module VoIP
    module Asterisk
      module ConfigFileGenerators
        class Queues < AsteriskConfigGenerator

          DEFAULT_GENERAL_SECTION = {
            :autofill => "yes"
          }

          attr_reader :general_section, :queue_definitions, :properties
          def initialize
            @general_section   = DEFAULT_GENERAL_SECTION.clone
            @properties        = {}
            @queue_definitions = []
            super
          end
          
          def queue(name)
            new_queue = QueueDefinition.new name
            yield new_queue if block_given?
            queue_definitions << new_queue
            new_queue
          end

          def to_s
            general_section.inject("[general]") { |section,(key,value)| section + "\n#{key}=#{value}" } + "\n\n" +
            queue_definitions.map(&:to_s).join("\n\n")
          end
          alias conf to_s
          
          def persistent_members(yes_no)
            boolean :persistentmembers => yes_no, :with => general_section
          end
          
          def monitor_type(symbol)
            criteria = {:monitor => "Monitor", :mix_monitor => "MixMonitor"}
            one_of_and_translate criteria, 'monitor-type' => symbol, :with => general_section
          end
          
          
          class QueueDefinition < AsteriskConfigGenerator

            DEFAULT_QUEUE_PROPERTIES = {
              :autofill              => 'yes',
              :eventwhencalled       => 'vars',
              :eventmemberstatus     => 'yes'
            }

            SUPPORTED_RING_STRATEGIES = [:ringall, :roundrobin, :leastrecent, :fewestcalls, :random, :rrmemory]
            
            DEFAULT_SOUND_FILES = {
              'queue-youarenext'   => 'queue-youarenext',
              'queue-thereare'     => 'queue-thereare',
              'queue-callswaiting' => 'queue-callswaiting',
              'queue-holdtime'     => 'queue-holdtime',
              'queue-minutes'      => 'queue-minutes',
              'queue-seconds'      => 'queue-seconds',
              'queue-thankyou'     => 'queue-thankyou',
              'queue-lessthan'     => 'queue-less-than',
              'queue-reporthold'   => 'queue-reporthold',
              'periodic-announce'  => 'queue-periodic-announce'
            }

            SOUND_FILE_SYMBOL_INTERPRETATIONS = {
              :you_are_next           => 'queue-youarenext',
              :there_are              => 'queue-thereare',
              :calls_waiting          => 'queue-callswaiting',
              :hold_time              => 'queue-holdtime',
              :minutes                => 'queue-minutes',
              :seconds                => 'queue-seconds',
              :thank_you              => 'queue-thankyou',
              :less_than              => 'queue-lessthan',
              :report_hold            => 'queue-reporthold',
              :periodic_announcement  => 'periodic-announce'
            }

            attr_reader :members, :name, :properties
            def initialize(name)
              @name        = name
              @members     = []
              @properties  = DEFAULT_QUEUE_PROPERTIES.clone
              @sound_files = DEFAULT_SOUND_FILES.clone
            end
            
            def to_s
              "[#{name}]\n" +
              properties.merge(@sound_files).map { |key, value| "#{key}=#{value}" }.join("\n") + "\n\n" +
              members.map { |member| "member => #{member}" }.join("\n")
            end

            def music_class(moh_identifier)
              string :musicclass => moh_identifier
            end

            def play_on_connect(sound_file)
              string :announce => sound_file
            end

            def strategy(symbol)
              one_of SUPPORTED_RING_STRATEGIES, :strategy => symbol
            end

            def service_level(seconds)
              int :servicelevel => seconds
            end

            def context(context_name)
              string :context => context_name
            end

            def timeout(seconds)
              int :timeout => seconds
            end

            def retry(seconds)
              int :retry => seconds
            end

            def weight(number)
              int :weight => number
            end

            def wrapup_time(seconds)
              int :wrapuptime => seconds
            end

            def autopause(yes_no)
              boolean :autopause => yes_no
            end

            def maximum_length(number)
              int :maxlen => number
            end

            def setinterfacevar(yes_no)
              boolean :setinterfacevar => yes_no
            end

            def announce_frequency(seconds)
              int "announce-frequency" => seconds
            end

            def periodically_announce(sound_file)
              string 'periodic-announce' => sound_file
            end

            def periodic_announce_frequency(seconds)
              int "periodic-announce-frequency" => seconds
            end

            def announce_hold_time(seconds)
              one_of [true, false, :once], "announce-holdtime" => seconds
            end

            def announce_round_seconds(yes_no_or_once)
              int "announce-round-seconds" => yes_no_or_once
            end

            def monitor_format(symbol)
              one_of [:wav, :gsm, :wav49], 'monitor-format' => symbol
            end
            
            def monitor_type(symbol)
              criteria = {:monitor => "Monitor", :mix_monitor => "MixMonitor"}
              one_of_and_translate criteria, 'monitor-type' => symbol
            end

            def join_empty(yes_no)
              boolean :joinempty => yes_no
            end
            
            def leave_when_empty(yes_no)
              boolean :leavewhenempty => yes_no
            end

            def report_hold_time(yes_no)
              boolean :reportholdtime => yes_no
            end
            
            def ring_in_use(yes_no)
              boolean :ringinuse => yes_no
            end

            def member_delay(seconds)
              int :memberdelay => seconds
            end
            
            def timeout_restart(yes_no)
              boolean :timeoutrestart => yes_no
            end
            
            # Give a Hash argument here to override the default sound files for this queue.
            #
            # Usage:
            #
            #   queue.sound_files :you_are_next          => 'queue-youarenext',
            #                     :there_are             => 'queue-thereare',
            #                     :calls_waiting         => 'queue-callswaiting',
            #                     :hold_time             => 'queue-holdtime',
            #                     :minutes               => 'queue-minutes',
            #                     :seconds               => 'queue-seconds',
            #                     :thank_you             => 'queue-thankyou',
            #                     :less_than             => 'queue-less-than',
            #                     :report_hold           => 'queue-reporthold',
            #                     :periodic_announcement => 'queue-periodic-announce'
            #
            # Note: the Hash values are the defaults. You only need to specify the ones you
            # wish to override.
            def sound_files(hash_of_files)
              hash_of_files.each_pair do |key, value|
                unless SOUND_FILE_SYMBOL_INTERPRETATIONS.has_key? key
                  message = "Unrecogized sound file identifier #{key.inspect}. " +
                        "Supported: " + SOUND_FILE_SYMBOL_INTERPRETATIONS.keys.map(&:inspect).to_sentence
                  raise ArgumentError, message
                end
                @sound_files[SOUND_FILE_SYMBOL_INTERPRETATIONS[key]] = value
              end
            end
            
            def member(driver)
              members << (driver.kind_of?(String) && driver =~ %r'/' ? driver : "Agent/#{driver}")
            end

          end

        end
      end
    end
  end
end
