require 'spec_helper'

GUID_REGEXP = /^[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$/i

module InvocationTestHelper
  def new_invocation(payload=@payload)
    Theatre::Invocation.new(@namespace, @block, @payload)
  end
end

describe "The lifecycle of an Invocation" do

  include InvocationTestHelper

  before :all do
    @block   = lambda {}
    @payload = 123
    @namespace = "/some/namespace"
  end

  it "should have an initial state of :new" do
    new_invocation.current_state.should eql(:new)
  end

  it "should not have a @queued_time until state becomes :queued" do
    invocation = new_invocation
    invocation.queued_time.should eql(nil)
    invocation.queued
    invocation.queued_time.should be_instance_of(Time)
    invocation.current_state.should eql(:queued)
  end

  it "should have a valid guid when instantiated" do
    new_invocation.unique_id.should =~ GUID_REGEXP
  end

  it "should execute the callback when moving to the 'start' state" do
    flexmock(@block).should_receive(:call).once
    invocation = new_invocation
    invocation.queued
    invocation.start
  end

end

describe "Using Invocations that've been ran through the Theatre" do

  it "should pass the payload to the callback" do
    destined_payload = [:i_feel_so_pretty, :OH, :SO, :PRETTY!]
    expecting_callback = lambda do |payload|
      payload.should equal(destined_payload)
    end
    invocation = Theatre::Invocation.new("/namespace/whatever", expecting_callback, destined_payload)
    invocation.queued
    invocation.start
  end

  it "should have a status of :error if an exception was raised and set the #error property" do
    invocation = Theatre::Invocation.new("/namespace/whatever", lambda { raise ArgumentError, "this error is intentional" })
    invocation.queued
    invocation.start
    invocation.current_state.should == :error
    invocation.should be_error
    invocation.error.should be_instance_of(ArgumentError)
  end

  it "should have a status of :success if no expection was raised" do
    callback = lambda { "No errors raised here!" }
    invocation = Theatre::Invocation.new("/namespace/whatever", callback)
    invocation.queued
    invocation.start
    invocation.current_state.should equal(:success)
    invocation.should be_success
  end

  it "should set the #returned_value property to the returned value callback when a payload was given" do
    doubler = lambda { |num| num * 2 }
    invocation = Theatre::Invocation.new('/foo/bar', doubler, 5)
    invocation.queued
    invocation.start
    invocation.returned_value.should equal(10)
  end

  it "should set the #returned_value property to the returned value callback when a payload was NOT given" do
    doubler = lambda { :ohai }
    invocation = Theatre::Invocation.new('/foo/bar', doubler)
    invocation.queued
    invocation.start
    invocation.returned_value.should equal(:ohai)
  end

  it "should set the #finished_time property when a success was encountered" do
    block = lambda {}
    invocation = Theatre::Invocation.new('/foo/bar', block)
    invocation.queued

    now = Time.now
    flexmock(Time).should_receive(:now).twice.and_return now

    invocation.start
    invocation.should be_success
  end

  it "should set the #finished_time property when a failure was encountered" do
    invocation = Theatre::Invocation.new('/foo/bar', lambda { raise LocalJumpError })
    invocation.queued

    now = Time.now
    flexmock(Time).should_receive(:now).twice.and_return now

    invocation.start
    invocation.should be_error
  end

  it "should set the #started_time property after starting" do
    invocation = Theatre::Invocation.new('/foo/bar', lambda { sleep 0.01 } )
    invocation.queued
    invocation.started_time.should be_nil
    invocation.start
    invocation.started_time.should be_kind_of(Time)
  end

  it "should properly calculate #execution_duration" do
    time_ago_difference = 60 * 5 # Five minutes
    time_now = Time.now
    time_ago = time_now - time_ago_difference

    invocation = Theatre::Invocation.new('/foo/bar', lambda {} )
    invocation.queued
    invocation.start

    invocation.send(:instance_variable_set, :@started_time, time_ago)
    invocation.send(:instance_variable_set, :@finished_time, time_now)

    invocation.execution_duration.should be_within(0.01).of(time_ago_difference.to_f)
  end

  it "should return the set value of returned_value when one has been set to a non-nil value" do
    return_nil = lambda { 123 }
    invocation = Theatre::Invocation.new("/namespace/whatever", return_nil)
    invocation.queued
    invocation.start
    invocation.returned_value.should eql(123)
  end

  it "should return nil for returned_value when it has been set to nil" do
    return_nil = lambda { nil }
    invocation = Theatre::Invocation.new("/namespace/whatever", return_nil)
    invocation.queued
    invocation.start
    invocation.returned_value.should eql(nil)
  end

  it "waiting on an Invocation should execute properly" do
    wait_on_invocation = lambda { 123 }
    invocation = Theatre::Invocation.new("/namespace/whatever", wait_on_invocation)
    invocation.queued
    invocation.start
    invocation.wait.should eql(123)
    invocation.success?.should eql(true)
  end

end
