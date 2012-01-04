module Adhearsion
  class CallController
    shared_examples_for "menu commands" do
      describe "#play_sound_files_for_menu" do
        let(:options) { Hash.new }
        let(:menu_instance) { Adhearsion::MenuDSL::Menu.new(options) {} }
        let(:sound_file) { "press a button" }
        let(:sound_files) { [sound_file] }

        it "should play the sound files for the menu" do
          subject.should_receive(:interruptible_play).with(sound_file).and_return("1")
          subject.play_sound_files_for_menu(menu_instance, sound_files)
        end

        it "should wait for digit if nothing is pressed during playback" do
          subject.should_receive(:interruptible_play).with(sound_file).and_return(nil)
          subject.should_receive(:wait_for_digit).with(menu_instance.timeout).and_return("1")
        end
      end#play_sound_files_for_menu

      describe "#menu" do
        
      end

    end#shared
  end
end
