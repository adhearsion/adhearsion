# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe Events do

    EventClass = Class.new
    ExceptionClass = Class.new StandardError

    before do
      Events.refresh!
    end

    it "should allow adding events to the queue and handle them appropriately" do
      e = nil
      latch = CountDownLatch.new 1

      Events.register_handler :event do |event|
        logger.info "Received an event!"
        e = event
        latch.countdown!
      end

      Events.trigger :event, :foo

      expect(latch.wait(2)).to be_truthy
      expect(e).to eq(:foo)
    end

    it "should allow executing events immediately" do
      e = nil

      Events.register_handler :event do |event|
        sleep 0.25
        e = event
      end

      Events.trigger_immediately :event, :foo

      expect(e).to eq(:foo)
    end

    it "should handle exceptions in event processing by raising the exception as an event" do
      e = nil
      latch = CountDownLatch.new 1

      Events.register_handler :exception do |event|
        e = event
        latch.countdown!
      end

      Events.register_handler :event, EventClass do |event|
        raise ExceptionClass
      end

      Events.trigger_immediately :event, EventClass.new

      expect(latch.wait(2)).to be_truthy
      expect(e).to be_a(ExceptionClass)
    end

    class FailingNotifier
      def notify(ex)
        warn "#{self} - #{ex.class} : #{ex.message}"
        raise Errno::ECONNREFUSED
      end
    end

    it "should not propagate exceptions which occur during exception event handling" do
      latch = CountDownLatch.new 1
      notifier = FailingNotifier.new

      exceptions = []
      Events.exception do |ex, logger|
        exceptions << ex
        begin
          notifier.notify ex
        ensure
          latch.countdown!
        end
      end

      begin
        raise "A-RUNTIME-FAILURE"
      rescue => ex
        Events.trigger :exception, ex
      end

      expect(latch.wait(2)).to be true

      expect(exceptions.size).to eql 1
      expect(exceptions.first).to be_a StandardError
      expect(exceptions.first).to_not be_a SystemCallError # ECONNREFUSED should not propagate
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

      expect(result).to eq(:bar)
    end

    describe '#draw' do
      it "should allow registering handlers by type" do
        result = nil
        Events.draw do
          event do
            logger.info "Got an event!"
            result = :foo
          end
        end

        Events.trigger_immediately :event

        expect(result).to eq(:foo)
      end
    end

  end
end
