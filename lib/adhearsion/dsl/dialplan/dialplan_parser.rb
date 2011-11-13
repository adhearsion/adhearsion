module Adhearsion
  module DSL
    class Dialplan
      #TODO: This is obsolete, but we still need it for Freeswitch until we port that to the new 0.8.0 APIs
      module DialplanParser

        # Create a container and then clone that. when the container is created
        # it should have all the contexts meta_def'd into it. for each call coming
        # in, the cloned copy has the variables meta_def'd and set as instance
        # variables

        #TODO: separate into smaller pieces
        def self.get_contexts
          envelope = ContextsEnvelope.new

          dialplans = Adhearsion.config.files_from_setting "paths", "dialplan"
          logger.warn "No dialplan files were found!" if dialplans.empty?

          {}.tap do |contexts|
            dialplans.each do |file|
              raise "Dialplan file #{file} does not exist!" unless File.exists? file
              envelope.instance_eval do
                eval File.read(file)
              end
              current_contexts = envelope.parsed_contexts
              current_contexts.each_pair do |name, block|
                if contexts.has_key? name
                  warn %'Dialplan context "#{name}" exists in both #{contexts[name].file} and #{file}.' +
                       %' Using the "#{name}" context from #{contexts[name].file}.'
                else
                  contexts[name] = OpenStruct.new.tap do |metadata|
                    metadata.file  = file
                    metadata.name  = name
                    metadata.block = block
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
