require File.join(File.dirname(__FILE__), 'config_generator')

module Adhearsion
  module VoIP
    module Asterisk
      module ConfigFileGenerators
        class Agents < AsteriskConfigGenerator

          attr_accessor :general_section, :agent_section, :agent_definitions, :agent_section_special
          def initialize
            @general_section       = {}
            @agent_section         = {}
            @agent_section_special = {} # Uses => separator
            @agent_definitions     = []

            super
          end

          def to_s
            AsteriskConfigGenerator.warning_message +
            general_section.inject("[general]") { |section,(key,value)| section + "\n#{key}=#{value}" } +
            agent_section.inject("\n[agents]")  { |section,(key,value)| section + "\n#{key}=#{value}" } +
            agent_section_special.inject("")    { |section,(key,value)| section + "\n#{key} => #{value}" } +
            agent_definitions.inject("\n") do |section,properties|
              section + "\nagent => #{properties[:id]},#{properties[:password]},#{properties[:name]}"
            end
          end
          alias conf to_s # Allows "agents.conf" if agents.kind_of?(Agents)

          def agent(id, properties)
            agent_definitions << {:id => id}.merge(properties)
          end

          # Group memberships for agents (may change in mid-file)
          # WHAT DOES GROUPING ACCOMPLISH?
          def groups(*args)
            agent_section[:group] = args.join(",")
          end

          # Define whether callbacklogins should be stored in astdb for
          # persistence. Persistent logins will be reloaded after
          # Asterisk restarts.
          def persistent_agents(yes_or_no)
            general_section[:persistentagents] = boolean_to_yes_no yes_or_no
          end

          # enable or disable a single extension from longing in as multiple
          # agents, defaults to enabled
          def allow_multiple_logins_per_extension(yes_or_no)
            general_section[:multiplelogin] = boolean_to_yes_no yes_or_no
          end

          # Define maxlogintries to allow agent to try max logins before
          # failed. Default to 3
          def max_login_tries(number_of_tries)
            agent_section[:maxlogintries] = number_of_tries
          end

          # Define autologoff times if appropriate.  This is how long
          # the phone has to ring with no answer before the agent is
          # automatically logged off (in seconds)
          def log_off_after_duration(time_in_seconds)
            agent_section[:autologoff] = time_in_seconds
          end

          # Define autologoffunavail to have agents automatically logged
          # out when the extension that they are at returns a CHANUNAVAIL
          # status when a call is attempted to be sent there.
          # Default is "no".
          def log_off_if_unavailable(yes_or_no)
            agent_section[:autologoffunavail] = boolean_to_yes_no yes_or_no
          end

          # Define ackcall to require an acknowledgement by '#' when
          # an agent logs in using agentcallbacklogin.  Default is "no".
          def require_hash_to_acknowledge(yes_or_no)
            agent_section[:ackcall] = boolean_to_yes_no yes_or_no
          end

          # Define endcall to allow an agent to hangup a call by '*'.
          # Default is "yes". Set this to "no" to ignore '*'.
          def allow_star_to_hangup(yes_or_no)
            agent_section[:endcall] = boolean_to_yes_no yes_or_no
          end

          # Define wrapuptime.  This is the minimum amount of time when
          # after disconnecting before the caller can receive a new call
          # note this is in milliseconds.
          def time_between_calls(time_in_seconds)
            agent_section[:wrapuptime] = (time_in_seconds * 1000).to_i
          end

          # Define the default musiconhold for agents
          # musiconhold => music_class
          def hold_music_class(music_class)
            agent_section_special[:musiconhold] = music_class.to_s
          end

          # TODO: I'm not exactly sure what this even does....

          # Define the default good bye sound file for agents
          # default to vm-goodbye
          def play_on_agent_goodbye(sound_file_name)
            agent_section_special[:agentgoodbye] = sound_file_name
          end

          # Define updatecdr. This is whether or not to change the source
          # channel in the CDR record for this call to agent/agent_id so
          # that we know which agent generates the call
          def change_cdr_source(yes_or_no)
            agent_section[:updatecdr] =  boolean_to_yes_no yes_or_no
          end

          # An optional custom beep sound file to play to always-connected agents.
          def play_for_waiting_keep_alive(sound_file)
            agent_section[:custom_beep] = sound_file
          end

          def record_agent_calls(yes_or_no)
            agent_section[:recordagentcalls] = boolean_to_yes_no yes_or_no
          end

          def recording_format(symbol)
            raise ArgumentError, "Unrecognized format #{symbol}" unless [:wav, :wav49, :gsm].include? symbol
            agent_section[:recordformat] = symbol
          end

          def recording_prefix(string)
            agent_section[:urlprefix] = string
          end

          def save_recordings_in(path_to_directory)
            agent_section[:savecallsin] = path_to_directory
          end

        end
      end
    end
  end
end
