module CallControllerTestHelpers
  include FlexMock::ArgumentTypes

  def self.included(test_case)
    test_case.let(:call_id) { rand }
    test_case.let(:call)    { Adhearsion::Call.new }

    test_case.subject { Adhearsion::CallController.new call }

    test_case.before do
      flexmock subject
      flexmock call, :write_command => true, :id => call_id
    end
  end

  def expect_message_waiting_for_response(message)
    subject.should_receive(:write_and_await_response).once.with(message).and_return message
    message.request!
  end

  def expect_component_execution(component)
    subject.should_receive(:execute_component_and_await_completion).once.with(component).and_return(component)
  end

  def expect_component_execution_asynchronously(component)
    subject.should_receive(:execute_component).once.with(component).and_return(component)
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
