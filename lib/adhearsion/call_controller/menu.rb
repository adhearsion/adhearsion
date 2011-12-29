module Adhearsion
  class CallController
    module Menu

      def menu(*args, &block)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        sound_files = args.flatten

        menu_instance = Punchblock::MenuDSL::Menu.new(options, &block)
        result_of_menu = nil

         while result_of_menu != Punchblock::MenuDSL::Menu::MenuResultDone
           if menu_instance.should_continue?
             result_of_menu = menu_instance.continue
           else
             menu_instance.execute_failure_hook
             return :failed
           end

           case result_of_menu
             when Punchblock::MenuDSL::Menu::MenuResultInvalid
               menu_instance.execute_invalid_hook
               menu_instance.restart!
               result_of_menu = nil
             when Punchblock::MenuDSL::Menu::MenuGetAnotherDigit
               next_digit = play_sound_files_for_menu(menu_instance, sound_files)
               if next_digit
                 menu_instance << next_digit
               else
                 case result_of_menu
                 when Punchblock::MenuDSL::Menu::MenuGetAnotherDigitOrFinish
                   jump_to result_of_menu.match_object, :extension => result_of_menu.new_extension
                   return true
                 when Punchblock::MenuDSL::Menu::MenuGetAnotherDigitOrTimeout
                   menu_instance.execute_timeout_hook
                   menu_instance.restart!
                   result_of_menu = nil
                 end
             end
             when Punchblock::MenuDSL::Menu::MenuResultFound
               jump_to result_of_menu.match_object, :extension => result_of_menu.new_extension
               return false
           end#case
         end#while
      end

      def play_sound_files_for_menu(menu_instance, sound_files)
        digit = nil
        if sound_files.any? && menu_instance.digit_buffer_empty?
          digit = interruptible_play(*sound_files)
        end
        digit || wait_for_digit(menu_instance.timeout)
      end

      def jump_to(match_object, overrides={})
      if match_object.block
        instance_exec overrides[:extension], &match_object.block
      else
        controller = match_object.match_payload
        controller_instance = controller.new(call)
        controller_instance.options = overrides
        controller_instance.run
      end
      end

    end#module
  end
end
