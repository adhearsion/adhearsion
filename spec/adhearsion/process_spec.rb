require 'spec_helper'

describe Adhearsion::Process, :focus => true do
  before :each do
    Adhearsion::Process.reset
  end

  it 'should trigger :shutdown events on shutdown' do
    flexmock(Adhearsion::Events).should_receive(:trigger_immediately).once.with(:shutdown)
    Adhearsion::Process.booted
    Adhearsion::Process.shutdown
  end
end