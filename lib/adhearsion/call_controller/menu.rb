module Adhearsion
  class CallController
    module Menu

      def menu(*args, &block)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        sound_files = args.flatten

        menu_instance = Punchblock::MenuDSL::Menu.new(options, &block)

         begin
           if menu_instance.should_continue?
             menu_instance.continue
           else
             menu_instance.execute_failure_hook
             return :failed
           end
         rescue Punchblock::MenuDSL::Menu::MenuResult => result_of_menu
           case result_of_menu
           when Punchblock::MenuDSL::Menu::MenuResultInvalid
             menu_instance.execute_invalid_hook
             menu_instance.restart!
           when Punchblock::MenuDSL::Menu::MenuGetAnotherDigit
             next_digit = play_sound_files_for_menu(menu_instance, sound_files)
             if next_digit
               menu_instance << next_digit
             else
               case result_of_menu
               when Punchblock::MenuDSL::Menu::MenuGetAnotherDigitOrFinish
                 jump_to result_of_menu.match_payload, :extension => result_of_menu.new_extension
               when Punchblock::MenuDSL::Menu::MenuGetAnotherDigitOrTimeout
                 menu_instance.execute_timeout_hook
                 menu_instance.restart!
               end
           end
           when Punchblock::MenuDSL::Menu::MenuResultFound
             p "JUMPING"
             jump_to result_of_menu.match_payload, :extension => result_of_menu.new_extension
             return false
           else
             raise "Unrecognized MenuResult! This may be a bug!"
           end

           retry
         end
      end

      def play_sound_files_for_menu(menu_instance, sound_files)
        digit = nil
        if sound_files.any? && menu_instance.digit_buffer_empty?
          digit = interruptible_play(*sound_files)
        end
        digit || wait_for_digit(menu_instance.timeout)
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
        #context = lookup_context_with_name(context) if context.kind_of?(Symbol) || (context.kind_of?(String) && context =~ /^[\w_]+$/)

        ## JRuby has a bug that prevents us from correctly determining the class name.
        ## See: http://jira.codehaus.org/browse/JRUBY-5026
        #if !(context.kind_of?(Adhearsion::DialPlan::DialplanContextProc) || context.kind_of?(Proc))
          #raise Adhearsion::DSL::Dialplan::ContextNotFoundException
        #end

        #if overrides.any?
          #overrides = overrides.symbolize_keys
          #if overrides.has_key?(:extension) && !overrides[:extension].kind_of?(Adhearsion::DSL::PhoneNumber)
            #overrides[:extension] = Adhearsion::DSL::PhoneNumber.new overrides[:extension]
          #end

          #overrides.each_pair do |key, value|
            #meta_def(key) { value }
          #end
        #end

        #raise Exception, context
        context.new(call).run
        #raise Adhearsion::DSL::Dialplan::ControlPassingException.new(context)
      end

      def lookup_context_with_name(context_name)
        begin
          send context_name
        rescue NameError
          raise Adhearsion::DSL::Dialplan::ContextNotFoundException
        end
      end

    end#module
  end
end
