# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Ask do
      include CallControllerTestHelpers

      describe "#play_sound_files_for_menu" do
        let(:options) { Hash.new }
        let(:menu_instance) { Adhearsion::MenuDSL::Menu.new(options) {} }
        let(:sound_file) { "press a button" }
        let(:sound_files) { [sound_file] }

        it "should play the sound files for the menu" do
          subject.should_receive(:interruptible_play).with(sound_file).and_return("1")
          subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
        end

        it "should wait for digit if nothing is pressed during playback" do
          subject.should_receive(:interruptible_play).with(sound_file).and_return(nil)
          subject.should_receive(:wait_for_digit).with(menu_instance.timeout).and_return("1")
          subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
        end

        context "when the menu is not interruptible" do
          let(:options) { { :interruptible => false } }

          it "should play the sound files and wait for digit" do
            subject.should_receive(:play).with(sound_file).and_return true
            subject.should_receive(:wait_for_digit).with(menu_instance.timeout).and_return("1")
            subject.play_sound_files_for_menu(menu_instance, sound_files).should be == '1'
          end
        end
      end#play_sound_files_for_menu

      describe "#jump_to" do
        let(:match_object) { flexmock(Class.new) }
        let(:overrides) { Hash.new(:extension => "1") }
        let(:block) { Proc.new() {} }

        it "calls instance_exec if the match object has a block" do
          match_object.should_receive(:block).and_return(block)
          subject.should_receive(:instance_exec).with(overrides[:extension], block)
          subject.jump_to(match_object, overrides)
        end

        it "calls invoke if the match object does not have a block" do
          match_object.should_receive(:block).and_return(false)
          match_object.should_receive(:match_payload).and_return(:payload)
          subject.should_receive(:invoke).with(:payload, overrides)
          subject.jump_to(match_object, overrides)
        end
      end#jump_to

      describe "#ask" do
        let(:sound_files) { ["press", "button"] }

        let(:menu_instance) { flexmock(MenuDSL::Menu.new({}) {}) }

        let(:result_done)                   { MenuDSL::Menu::MenuResultDone.new }
        let(:result_terminated)             { MenuDSL::Menu::MenuTerminated.new }
        let(:result_limit_reached)          { MenuDSL::Menu::MenuLimitReached.new }
        let(:result_invalid)                { MenuDSL::Menu::MenuResultInvalid.new }
        let(:result_get_another_or_timeout) { MenuDSL::Menu::MenuGetAnotherDigitOrTimeout.new }
        let(:result_get_another_or_finish)  { MenuDSL::Menu::MenuGetAnotherDigitOrFinish.new(:match_object, :new_extension) }
        let(:result_found)                  { MenuDSL::Menu::MenuResultFound.new(:match_object, :new_extension) }

        before(:each) do
          flexmock(MenuDSL::Menu).should_receive(:new).and_return(menu_instance)
        end

        it "exits the function if MenuResultDone" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_done)
          result = subject.ask(sound_files) {}
          result.should be == :done
        end

        it "exits the function if MenuTerminated" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_terminated)
          result = subject.ask(sound_files) {}
          result.should be == :done
        end

        it "exits the function if MenuLimitReached" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_limit_reached)
          result = subject.ask(sound_files) {}
          result.should be == :done
        end

        it "executes failure hook and returns :failure if menu fails" do
          menu_instance.should_receive(:should_continue?).and_return(false)
          menu_instance.should_receive(:execute_failure_hook)
          result = subject.ask(sound_files) {}
          result.should be == :failed
        end

        it "executes invalid hook if input is invalid" do
          menu_instance.should_receive(:should_continue?).twice.and_return(true)
          menu_instance.should_receive(:continue).and_return(result_invalid, result_done)
          menu_instance.should_receive(:execute_invalid_hook)
          menu_instance.should_receive(:restart!)
          subject.ask(sound_files) {}
        end

        it "plays audio, then executes timeout hook if input times out" do
          menu_instance.should_receive(:should_continue?).twice.and_return(true)
          menu_instance.should_receive(:continue).and_return(result_get_another_or_timeout, result_done)
          subject.should_receive(:play_sound_files_for_menu).with(menu_instance, sound_files).and_return(nil)
          menu_instance.should_receive(:execute_timeout_hook)
          menu_instance.should_receive(:restart!)
          subject.ask(sound_files) {}
        end

        it "plays audio, then adds digit to digit buffer if input is received" do
          menu_instance.should_receive(:should_continue?).twice.and_return(true)
          menu_instance.should_receive(:continue).and_return(result_get_another_or_timeout, result_done)
          subject.should_receive(:play_sound_files_for_menu).with(menu_instance, sound_files).and_return("1")
          menu_instance.should_receive(:<<).with("1")
          subject.ask(sound_files) {}
        end

        it "plays audio, then jumps to payload when input is finished" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_get_another_or_finish)
          subject.should_receive(:play_sound_files_for_menu).with(menu_instance, sound_files).and_return(nil)
          subject.should_receive(:jump_to).with(:match_object, :extension => :new_extension)
          subject.ask(sound_files) {}
        end

        it "jumps to payload when result is found" do
          menu_instance.should_receive(:should_continue?).and_return(true)
          menu_instance.should_receive(:continue).and_return(result_found)
          subject.should_receive(:jump_to).with(:match_object, :extension => :new_extension)
          subject.ask(sound_files) {}
        end

      end#describe

      describe "#menu" do
        it "should be an alias for #ask" do
          subject.method(:menu).should be == subject.method(:ask)
        end
      end

    end#shared
  end
end
