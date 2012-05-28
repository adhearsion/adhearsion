# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Output do
      include CallControllerTestHelpers

      describe "#new_play" do
        it "should return a Play component targetted at the current controller" do
          play = controller.new_play
          play.should be_a Output::Play
          play.controller.should be controller
        end
      end

      [:say, :play, :play_audio, :play_time, :play_numeric, :interruptible_play].each do |method_name|
        describe "##{method_name}" do
          it "should delegate to a new play component" do
            play_component = flexmock Output::Play.new(controller)
            controller.should_receive(:new_play).and_return play_component
            play_component.should_receive(method_name).once.with 'foo'
            controller.send method_name, 'foo'
          end
        end
      end

      describe "#speak" do
        it "should be an alias for #say" do
          subject.method(:speak).should be == subject.method(:say)
        end
      end
    end
  end
end
