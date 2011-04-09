require 'spec_helper'

require 'adhearsion/voip/dsl/dialplan/dispatcher'

module StandardDispatcherBehavior
  def xtest_standard_dispatcher_behavior
    #"This it looks bogus.  Not finished?  Let's not check in failing specs ever if we can help it."
    returned_event_command = Adhearsion::VoIP::DSL::Dialplan::EventCommand.new "ilikesexypants"
    linking_event_command = Adhearsion::VoIP::DSL::Dialplan::EventCommand.new "ihavesexypants" do
      returned_event_command
    end

    dispatcher = @dispatcher_class.new MyFactory
    dispatcher.should_receive(:dispatch!).with(linking_event_command, returned_event_command).and_return(linking_event_command, returned_event_command)
    # returned_event_command.should_receive(:command_block).and_return nil
    dispatcher.dispatch! linking_event_command
  end
end

class NilDispatcher < Adhearsion::VoIP::DSL::Dialplan::CommandDispatcher
  def dispatch!(string)
    # Would send it off to the PBX here (or prepend something to the String)
  end
end

class EvalDispatcher < Adhearsion::VoIP::DSL::Dialplan::CommandDispatcher
  def dispatch!(event)
    eval event.app.to_s
  end
end

class MyFactory

  def initialize(context)
    @context = context
  end

  def sequence
    all = []
    EventCommand.new("2", :response => Numeric) do |response|
      all << response
      all.size > 3 ? all : nil
    end
  end
end
