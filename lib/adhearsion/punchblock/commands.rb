module Adhearsion
  module Punchblock
    module Commands
      extend ActiveSupport::Autoload

      autoload :Conference
      autoload :Dial
      autoload :Input
      autoload :Output
      autoload :Record

      include Punchblock::Command
      include Punchblock::Component
      include Conference
      include Dial
      include Input
      include Output
      include Record
      include MenuDSL

      def accept(headers = nil)
        call.accept headers
      end

      def answer(headers = nil)
        call.answer headers
      end

      def reject(reason = :busy, headers = nil)
        call.reject reason, headers
      end

      def hangup(headers = nil)
        call.hangup! headers
      end

      def mute
        write_and_await_response ::Punchblock::Command::Mute.new
      end

      def unmute
        write_and_await_response ::Punchblock::Command::Unmute.new
      end

      def write_and_await_response(command, timeout = nil)
        call.write_and_await_response command, timeout
      end
      alias :execute_component :write_and_await_response

      def execute_component_and_await_completion(component)
        write_and_await_response component

        yield component if block_given?

        complete_event = component.complete_event
        raise StandardError, complete_event.reason.details if complete_event.reason.is_a? Punchblock::Event::Complete::Error
        component
      end

      def menu(*args, &block)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        sound_files = args.flatten

        menu_instance = Punchblock::MenuDSL::Menu.new(options, &block)

        initial_digit_prompt = sound_files.any?

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
            jump_to result_of_menu.match_payload, :extension => result_of_menu.new_extension
          else
            raise "Unrecognized MenuResult! This may be a bug!"
          end

          retry
        end
      end

    end
  end
end
