module Adhearsion
  module VoIP
    module Asterisk
      module Commands
        class Menu
  
          attr_reader :tries, :timeout, :menu_definitions, :sound_files
          def initialize(*sound_files, &block)
            options     = sound_files.last.kind_of?(Hash) ? sound_files.pop : {}
        	  timeout     = options[:timeout] || 5.seconds
        	  max_tries   = options[:tries] || 1
        	  tries_count = 0
            @sound_files = sound_files
            @tries   = options[:tries] || 1
            @timeout = options[:timeout] || 5
            @menu_definitions = Menu::MenuBuilder.new
    
        	  yield menu_definitions

          end
  
          
  
          def execute_with_result(result)
            @result = result
        	  potential_matches = menu_definitions.potential_matches_for result
        	  multiple_matches  = potential_matches.select { |(first,*rest)| first == :multiple_matches }
        	  number_of_matches = ( potential_matches.size - multiple_matches.size +
        	                        multiple_matches.map { |first,(num,*rest)| num }.sum)

        	  if number_of_matches.zero?
        	    
        	    tries_count += 1
        	    if tries_count == max_tries
                
              else
                redo
              end
            elsif number_of_matches.equal? 1
              # Need to check if the potential match is an exact match.
              pattern, context_name = potential_matches.first
              if pattern != :multiple_matches && (pattern === result || (result =~ /^\d+$/ && pattern === result.to_i))
                new_context = send context_name rescue nil
                raise LocalJumpError, "Could not find context with name '#{context_name}'!" unless new_context
                raise Adhearsion::VoIP::DSL::Dialplan::ControlPassingException.new(new_context)
              else
                # It's not an exact match! premature_timeout!
                menu_definitions.execute_hook_for :premature_timeout, result
                tries_count += 1
                if tries_count == max_tries
                  menu_definitions.execute_hook_for :failure, result
                else
                  redo
                end
              end
            else
              # result_string = result.to_s
              # result_numeric = result_string.to_i if result_string =~ /^\d+$/
              # exact_match = potential_matches.find do |(pattern, *rest)|
              #   pattern === result || pattern === result_string || pattern === result_numeric
              # end

              # Too many potential_matches still and no exact match. We need to get another digit
              new_input = wait_for_digit timeout
              if new_input
                result = result.to_s + new_input.to_s
              else
                menu_definitions.execute_hook_for :premature_timeout, result
              end
              redo
            end
          end
          
          private
          
          def invalid!
            menu_definitions.execute_hook_for :invalid, @result
          end
          
          def failure!
            menu_definitions.execute_hook_for :failure, @result
          end
          
          def timeout!
            menu_definitions.execute_hook_for :premature_timeout, @result
          end

          class MatchPattern
            def initialize(&block)
              meta_def(:matches?, &block)
            end
          end
  
          class MenuBuilder

            def initialize
              @patterns = []
              @menu_callbacks = {}
            end

            def method_missing(name, *patterns, &block)
              name_string = name.to_s
              if patterns.empty? && name_string.ends_with?('?')
                @patterns << [:custom, [name_string.chop.to_sym, block]]
              elsif !patterns.empty? && !block_given?
                @patterns.concat patterns.map { |pattern| [pattern, name] }
              else raise ArgumentError
              end

              nil
            end

            def execute_hook_for(symbol, input)
              callback = @menu_callbacks[symbol]
              callback.call input if callback
            end

            def on_invalid(&block)
              raise LocalJumpError, "Must supply a block!" unless block_given?
              @menu_callbacks[:invalid] = block
            end

            def on_premature_timeout(&block)
              raise LocalJumpError, "Must supply a block!" unless block_given?
              @menu_callbacks[:premature_timeout] = block
            end

            def on_failure(&block)
              raise LocalJumpError, "Must supply a block!" unless block_given?
              @menu_callbacks[:failure] = block
            end

            def potential_matches_for(result)
          	  result_string  = result.to_s
          	  result_numeric = result.to_i if result_string =~ /^\d+$/

              all_matches = []
              @patterns.each do |pattern_with_metadata|
                pattern, action_info = pattern_with_metadata
                case pattern
                  when :custom
                    context_name, block = action_info
                    matches_from_block = block.call(result_string).to_a
                    raise "block for context #{context_name}? didn't return an Array or nil!" unless matches_from_block.kind_of?(Array)
                    all_matches.concat matches_from_block.map { |match| [match, context_name] }
                  when Range
                    matches_in_range = pattern.to_a.select { |num| num.to_s.starts_with?(result_string) }
                    all_matches << [:multiple_matches, [matches_in_range.size, *pattern_with_metadata]] if matches_in_range.any?
                  when Fixnum
                    all_matches << pattern_with_metadata if pattern.to_s.starts_with?(result_string)
                  when String
                    all_matches << pattern_with_metadata if pattern.starts_with? result_string
                  else
                    if pattern === result || pattern === result_string || pattern === result_numeric
                      all_matches << pattern_with_metadata 
                    end
                end
              end
        	    all_matches
            end

          end

        end
      end
    end
  end
end