# encoding: utf-8

module CallControllerTestHelpers
  include FlexMock::ArgumentTypes

  def self.included(test_case)
    test_case.let(:call_id) { new_uuid }
    test_case.let(:call)    { Adhearsion::Call.new }
    test_case.let(:block)   { nil }

    test_case.subject do
      case test_case.describes
      when Class
        test_case.describes
      when Module
        Class.new Adhearsion::CallController
      end.new call, :doo => :dah, &block
    end

    test_case.before do
      flexmock subject
      flexmock call, :write_command => true, :id => call_id
    end
  end

  def expect_message_waiting_for_response(message)
    subject.should_receive(:write_and_await_response).once.with(message).and_return message
    message.request!
  end

  def expect_message_of_type_waiting_for_response(message)
    subject.should_receive(:write_and_await_response).once.with(message.class).and_return message
    message.request!
  end

  def expect_component_execution(component)
    subject.should_receive(:execute_component_and_await_completion).once.with(component).and_return(component)
  end

  def mock_with_potential_matches(potential_matches)
    Adhearsion::Punchblock::MenuDSL::CalculatedMatch.new :potential_matches => potential_matches
  end

  def mock_with_exact_matches(exact_matches)
    Adhearsion::Punchblock::MenuDSL::CalculatedMatch.new :exact_matches => exact_matches
  end

  def mock_with_potential_and_exact_matches(potential_matches, exact_matches)
    Adhearsion::Punchblock::MenuDSL::CalculatedMatch.new :potential_matches => potential_matches, :exact_matches => exact_matches
  end
end
