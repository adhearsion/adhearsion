# encoding: utf-8

module CallControllerTestHelpers
  def self.included(test_case)
    test_case.let(:call_id)     { new_uuid }
    test_case.let(:call)        { Adhearsion::Call.new }
    test_case.let(:block)       { nil }
    test_case.let(:metadata)    { {doo: :dah} }
    test_case.let(:controller)  { new_controller test_case.describes }

    test_case.subject { controller }

    test_case.before do
      call.stub :write_command => true, :id => call_id
    end
  end

  def new_controller(target = nil)
    case target
    when Class
      raise "Your described class should inherit from Adhearsion::CallController" unless target.ancestors.include?(Adhearsion::CallController)
      target
    when Module, nil
      Class.new Adhearsion::CallController
    end.new call, metadata, &block
  end

  def expect_message_waiting_for_response(message = nil, fail = false, &block)
    expectation = controller.should_receive(:write_and_await_response, &block).once
    expectation = expectation.with message if message
    if fail
      expectation.and_raise fail
    else
      expectation.and_return message
    end
  end

  def expect_message_of_type_waiting_for_response(message)
    controller.should_receive(:write_and_await_response).once.with(kind_of(message.class)).and_return message
  end

  def expect_component_execution(component, fail = false)
    expectation = controller.should_receive(:execute_component_and_await_completion).once.with(component)
    if fail
      expectation.and_raise fail
    else
      expectation.and_return component
    end
  end

  def expect_input_component_complete_event(utterance)
    complete_event = Punchblock::Event::Complete.new
    complete_event.stub reason: mock(utterance: utterance, name: :input)
    Punchblock::Component::Input.any_instance.stub(complete?: true, complete_event: complete_event)
  end
end
