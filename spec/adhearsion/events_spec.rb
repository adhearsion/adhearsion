# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Events do

    EventClass = Class.new
    ExceptionClass = Class.new StandardError

    before do
      Events.refresh!
    end

    it "should have a GirlFriday::Queue to handle events" do
      Events.queue.should be_a GirlFriday::WorkQueue
    end

    it "should allow adding events to the queue and handle them appropriately" do
      t = nil
      o = nil
      latch = CountDownLatch.new 1

      Events.instance.should_receive(:handle_message).and_return do |message|
        t = message.type
        o = message.object
        latch.countdown!
      end

      Events.trigger :event, :foo

      latch.wait(2).should be_true
      t.should be == :event
      o.should be == :foo
    end

    it "should allow executing events immediately" do
      t = nil
      o = nil

      Events.instance.should_receive(:handle_message).and_return do |message|
        sleep 0.25
        t = message.type
        o = message.object
      end

      Events.trigger_immediately :event, :foo

      t.should be == :event
      o.should be == :foo
    end

    it "should handle events using registered guarded handlers" do
      result = nil

      Events.register_handler :event, EventClass do |event|
        result = :foo
      end

      Events.trigger_immediately :event, EventClass.new

      result.should be == :foo

      Events.clear_handlers :event, EventClass
    end

    it "should handle exceptions in event processing by raising the exception as an event" do
      Events.instance.should_receive(:trigger).with(:exception, kind_of(ExceptionClass)).once

      Events.register_handler :event, EventClass do |event|
        raise ExceptionClass
      end

      Events.trigger_immediately :event, EventClass.new
      Events.clear_handlers :event, EventClass
    end

    it "should implicitly pass on all handlers" do
      result = nil

      Events.register_handler :event, EventClass do |event|
        result = :foo
      end

      Events.register_handler :event, EventClass do |event|
        result = :bar
      end

      Events.trigger_immediately :event, EventClass.new

      result.should be == :bar

      Events.clear_handlers :event, EventClass
    end

    it "should respond_to? any methods corresponding to classes for which handlers are defined" do
      Events.register_handler :event_type_1 do |event|
      end

      Events.should respond_to(:event_type_1)
      Events.should_not respond_to(:event_type_2)
    end

    describe '#draw' do
      it "should allow registering handlers by type" do
        result = nil
        Events.draw do
          event do
            result = :foo
          end
        end

        Events.trigger_immediately :event

        result.should be == :foo

        Events.clear_handlers :event
      end
    end

  end
end
