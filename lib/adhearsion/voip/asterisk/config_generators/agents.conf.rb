require File.join(File.dirname(__FILE__), 'config_generator')

module Adhearsion
  module VoIP
    module Asterisk
      module ConfigFileGenerators
        class Agents < AsteriskConfigGenerator
          a = :delme
  
          AGENTS_OPTION_TRANSLATIONS = {
            
            # Define maxlogintries to allow agent to try max logins before
            # failed.
            # default to 3
            a => :multiplelogin,
    
            # Define autologoff times if appropriate.  This is how long
            # the phone has to ring with no answer before the agent is
            # automatically logged off (in seconds)
            a => :maxlogintries,
    
            # Define autologoffunavail to have agents automatically logged
            # out when the extension that they are at returns a CHANUNAVAIL
            # status when a call is attempted to be sent there.
            # Default is "no".
            a => :autologoff,
    
            # Define ackcall to require an acknowledgement by '#' when
            # an agent logs in using agentcallbacklogin.  Default is "no".
            a => :autologoffunavail,
    
            # Define endcall to allow an agent to hangup a call by '*'.
            # Default is "yes". Set this to "no" to ignore '*'.
            a => :ackcall,
    
            # Define wrapuptime.  This is the minimum amount of time when
            # after disconnecting before the caller can receive a new call
            # note this is in milliseconds.
            a => :endcall,
    
            # Define the default musiconhold for agents
            # musiconhold => music_class
            a => :wrapuptime,
    
            # Define the default good bye sound file for agents
            # default to vm-goodbye
            a => :musiconhold,
    
            # Define updatecdr. This is whether or not to change the source 
            # channel in the CDR record for this call to agent/agent_id so 
            # that we know which agent generates the call
            a => :musiconhold,
    
            # Group memberships for agents (may change in mid-file)
            a => :agentgoodbye,
    
            # Define updatecdr. This is whether or not to change the source 
            # channel in the CDR record for this call to agent/agent_id so 
            # that we know which agent generates the call
            a => :updatecdr,
    
            # a => :group, # WHAT DOES GROUPING ACCOMPLISH?
    
            # An optional custom beep sound file to play to always-connected agents. 
            a => :custom_beep # THIS IS PRETTY RETARDED
          }
  
          attr_accessor :attr_names
          def initialize(&block)
            yield self
          end

          def persistent_agents
            # Define whether callbacklogins should be stored in astdb for
            # persistence. Persistent logins will be reloaded after
            # Asterisk restarts.
          end

          def groups
            # THIS IS PRETY COMPLICAted
          end
  
          # Should hold a bunch of shit here.
          def recording
                # 
                # a => :recordagentcalls,
                # 
                # 
                # a => :recordformat,
                # 
                # 
                # a => :urlprefix,
                # 
                # 
                # a => :savecallsin,
                # 
          end

        end
      end
    end
  end
end