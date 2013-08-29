# encoding: utf-8

require 'spec_helper'
require 'ruby_speech'

module Adhearsion
  class CallController
    describe Input do
      include CallControllerTestHelpers

      describe "#play_sound_files_for_menu" do
        let(:renderer_options) { { renderer: nil } }
        let(:options) { Hash.new }
        let(:menu_instance) { MenuDSL::Menu.new(options) }
        let(:sound_file) { "press a button" }
        let(:sound_files) { [sound_file] }

        it "should play the sound files for the menu" do
          subject.should_receive(:interruptible_play).with(sound_file, renderer_options).and_return("1")
          subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
        end

        it "should wait for digit if nothing is pressed during playback" do
          subject.should_receive(:interruptible_play).with(sound_file, renderer_options).and_return(nil)
          subject.should_receive(:wait_for_digit).with(menu_instance.timeout).and_return("1")
          subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
        end

        context "with a renderer specified" do
          let(:options) { { :renderer => :native } }
          let(:renderer_options) { { renderer: :native } }
          it "should play the sound files for the menu" do
            subject.should_receive(:interruptible_play).with(sound_file, renderer_options).and_return("1")
            subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
          end

        end

        context "when the menu is not interruptible" do
          let(:options) { { :interruptible => false } }
          it "should play the sound files and wait for digit" do
            subject.should_receive(:play).with(sound_file, renderer_options).and_return true
            subject.should_receive(:wait_for_digit).with(menu_instance.timeout).and_return("1")
            subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
          end
        end

        context "with a renderer specified and not interruptible" do
          let(:options) { { :renderer => :native, :interruptible => false } }
          let(:renderer_options) { { renderer: :native } }
          it "should pass the renderer option to #play" do
            subject.should_receive(:play).with(sound_file, renderer_options).and_return true
            subject.should_receive(:wait_for_digit).with(menu_instance.timeout).and_return("1")
            subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
          end
        end
      end#play_sound_files_for_menu

      describe "#wait_for_digit" do
        let(:timeout) { 2 }
        let(:timeout_ms) { 2000 }

        let(:grxml) {
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
            rule id: 'inputdigits', scope: 'public' do
              one_of do
                0.upto(9) { |d| item { d.to_s } }
                item { "#" }
                item { "*" }
              end
            end
          end
        }

        let(:input_component) {
          Punchblock::Component::Input.new(
            { :mode => :dtmf,
              :initial_timeout => timeout_ms,
              :inter_digit_timeout => timeout_ms,
              :grammar => {
                :value => grxml.to_s
              }
            }
          )
        }

        let(:utterance) { 'dtmf-5' }

        def expect_component_complete_event
          expect_input_component_complete_event utterance
        end

        it "sends the correct input component" do
          expect_component_complete_event
          subject.should_receive(:execute_component_and_await_completion).once.with(input_component).and_return input_component
          subject.wait_for_digit timeout
        end

        it "returns the correct pressed digit" do
          expect_component_complete_event
          subject.should_receive(:execute_component_and_await_completion).once.with(kind_of(Punchblock::Component::Input)).and_return input_component
          subject.wait_for_digit(timeout).should be == '5'
        end

        context "when the utterance does not have dtmf- prefix" do
          let(:utterance) { '5' }

          it "returns the correct pressed digit" do
            expect_component_complete_event
            subject.should_receive(:execute_component_and_await_completion).once.with(kind_of(Punchblock::Component::Input)).and_return input_component
            subject.wait_for_digit(timeout).should be == '5'
          end
        end

        context "with a nil timeout" do
          let(:timeout)     { nil }
          let(:timeout_ms)  { nil }

          it "does not set a timeout on the component" do
            expect_component_complete_event
            subject.should_receive(:execute_component_and_await_completion).once.with(input_component).and_return input_component
            subject.wait_for_digit timeout
          end
        end
      end # wait_for_digit

      describe "#jump_to" do
        let(:match_object) { Class.new }
        let(:overrides) { Hash.new(:extension => "1") }
        let(:block) { Proc.new {} }

        it "calls instance_exec if the match object has a block" do
          match_object.stub(:block => block)
          subject.should_receive(:instance_exec).with(overrides[:extension], &block)
          subject.jump_to(match_object, overrides)
        end

        it "calls invoke if the match object does not have a block" do
          match_object.should_receive(:block).and_return(false)
          match_object.should_receive(:match_payload).and_return(:payload)
          subject.should_receive(:invoke).with(:payload, overrides)
          subject.jump_to(match_object, overrides)
        end
      end#jump_to

      describe "#menu" do
        let(:sound_files) { ["press", "button"] }

        let(:menu_instance) do
          MenuDSL::Menu.new { match(1) {} }
        end

        let(:result_done)                   { MenuDSL::Menu::MenuResultDone.new }
        let(:result_terminated)             { MenuDSL::Menu::MenuTerminated.new }
        let(:result_limit_reached)          { MenuDSL::Menu::MenuLimitReached.new }
        let(:result_invalid)                { MenuDSL::Menu::MenuResultInvalid.new }
        let(:result_get_another_or_timeout) { MenuDSL::Menu::MenuGetAnotherDigitOrTimeout.new }
        let(:result_get_another_or_finish)  { MenuDSL::Menu::MenuGetAnotherDigitOrFinish.new(:match_object, :new_extension) }
        let(:result_found)                  { MenuDSL::Menu::MenuResultFound.new(:match_object, :new_extension) }

        let(:status) { :foo }
        let(:response) { '1234' }

        before do
          menu_instance.stub :status => status, :result => response
          MenuDSL::Menu.should_receive(:new).and_return(menu_instance)
        end

        it "logs a warning about dropped DTMF" do
          menu_instance.should_receive(:continue).and_return(result_done)

          call.logger.should_receive(:warn).with(/deprecated/)
          subject.menu sound_files
        end

        it "exits the function if MenuResultDone" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_done)
          result = subject.menu sound_files
          result.menu.should be menu_instance
          result.response.should be response
        end

        it "exits the function if MenuTerminated" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_terminated)
          result = subject.menu sound_files
          result.menu.should be menu_instance
          result.response.should be response
        end

        it "exits the function if MenuLimitReached" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_limit_reached)
          result = subject.menu sound_files
          result.menu.should be menu_instance
          result.response.should be response
        end

        it "executes failure hook and returns :failure if menu fails" do
          menu_instance.should_receive(:should_continue?).and_return(false)
          menu_instance.should_receive(:execute_failure_hook).once
          result = subject.menu sound_files
          result.menu.should be menu_instance
          result.response.should be response
        end

        it "executes invalid hook if input is invalid" do
          menu_instance.should_receive(:should_continue?).twice.and_return(true)
          menu_instance.should_receive(:continue).and_return(result_invalid, result_done)
          menu_instance.should_receive(:execute_invalid_hook).once
          menu_instance.should_receive(:restart!).once
          result = subject.menu sound_files
          result.menu.should be menu_instance
          result.response.should be response
        end

        it "plays audio, then executes timeout hook if input times out" do
          menu_instance.should_receive(:should_continue?).twice.and_return(true)
          menu_instance.should_receive(:continue).and_return(result_get_another_or_timeout, result_done)
          subject.should_receive(:play_sound_files_for_menu).with(menu_instance, sound_files).and_return(nil)
          menu_instance.should_receive(:execute_timeout_hook).once
          menu_instance.should_receive(:restart!).once
          subject.menu sound_files
        end

        it "plays audio, then adds digit to digit buffer if input is received" do
          menu_instance.should_receive(:should_continue?).twice.and_return(true)
          menu_instance.should_receive(:continue).and_return(result_get_another_or_timeout, result_done)
          subject.should_receive(:play_sound_files_for_menu).with(menu_instance, sound_files).and_return("1")
          menu_instance.should_receive(:<<).with("1").once
          subject.menu sound_files
        end

        it "plays audio, then jumps to payload when input is finished" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_get_another_or_finish)
          subject.should_receive(:play_sound_files_for_menu).with(menu_instance, sound_files).and_return(nil)
          subject.should_receive(:jump_to).with(:match_object, :extension => :new_extension).once
          subject.menu sound_files
        end

        it "jumps to payload when result is found" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_found)
          subject.should_receive(:jump_to).with(:match_object, :extension => :new_extension).once
          result = subject.menu sound_files
          result.menu.should be menu_instance
          result.response.should be response
        end

        context "if a digit limit is specified" do
          it "should raise an ArgumentError"
        end

        context "if a terminator digit is specified" do
          it "should raise an ArgumentError"
        end

      end#describe

      describe "#ask" do
        let(:sound_files) { ["press", "button"] }

        context "mocking out the menu" do
          let(:menu_instance) { MenuDSL::Menu.new :limit => 2 }

          let(:result_done)                   { MenuDSL::Menu::MenuResultDone.new }
          let(:result_terminated)             { MenuDSL::Menu::MenuTerminated.new }
          let(:result_limit_reached)          { MenuDSL::Menu::MenuLimitReached.new }
          let(:result_invalid)                { MenuDSL::Menu::MenuResultInvalid.new }
          let(:result_get_another_or_timeout) { MenuDSL::Menu::MenuGetAnotherDigitOrTimeout.new }
          let(:result_get_another_or_finish)  { MenuDSL::Menu::MenuGetAnotherDigitOrFinish.new(:match_object, :new_extension) }
          let(:result_found)                  { MenuDSL::Menu::MenuResultFound.new(:match_object, :new_extension) }

          before do
            menu_instance
            MenuDSL::Menu.should_receive(:new).and_return(menu_instance)
          end

          it "logs a warning about dropped DTMF" do
            menu_instance.should_receive(:continue).and_return(result_done)

            call.logger.should_receive(:warn).with(/deprecated/)
            subject.ask sound_files
          end

          it "exits the function if MenuResultDone" do
            menu_instance.should_receive(:continue).and_return(result_done)
            result = subject.ask sound_files
            result.menu.should be menu_instance
            result.response.should == ''
          end

          it "exits the function if MenuTerminated" do
            menu_instance.should_receive(:continue).and_return(result_terminated)
            result = subject.ask sound_files
            result.menu.should be menu_instance
            result.response.should == ''
          end

          it "exits the function if MenuLimitReached" do
            menu_instance.should_receive(:continue).and_return(result_limit_reached)
            result = subject.ask sound_files
            result.menu.should be menu_instance
            result.response.should == ''
          end

          it "plays audio, then executes timeout hook if input times out" do
            menu_instance.should_receive(:continue).and_return(result_get_another_or_timeout)
            subject.should_receive(:play_sound_files_for_menu).once.with(menu_instance, sound_files).and_return(nil)
            result = subject.ask sound_files
            result.menu.should be menu_instance
            result.response.should be == ''
            result.status.should be :timeout
          end

          it "plays audio, then adds digit to digit buffer if input is received" do
            menu_instance.should_receive(:continue).and_return(result_get_another_or_timeout, result_done)
            subject.should_receive(:play_sound_files_for_menu).once.with(menu_instance, sound_files).and_return("1")
            menu_instance.should_receive(:<<).with("1").once
            subject.ask sound_files
          end
        end

        context "with a block passed" do
          it "validates the buffer using that block, terminating on something truthy" do
            subject.should_receive(:play_sound_files_for_menu).twice.and_return("1")
            result = subject.ask sound_files, limit: 3 do |buffer|
              buffer == '11'
            end
            result.status.should == :validator_terminated
            result.response.should == '11'
          end
        end

      end#describe

    end#shared
  end
end
