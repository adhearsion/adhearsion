module PunchblockCommandTestHelpers
  include FlexMock::ArgumentTypes

  def self.included(test_case)
    test_case.let :mock_execution_environment do
      flexmock Object.new.tap { |ee| ee.extend Adhearsion::Punchblock::Commands }, :call => mock_call
    end

    test_case.let(:call_id) { rand }

    test_case.let :mock_call do
      flexmock :write_command => true, :id => call_id
    end
  end

  def expect_message_waiting_for_response(message)
    mock_execution_environment.should_receive(:write_and_await_response).once.with(message).and_return message
    message.request!
  end

  def expect_component_execution(component)
    mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(component).and_return(component)
  end

  def expect_component_execution_asynchronously(component)
    mock_execution_environment.should_receive(:execute_component).once.with(component).and_return(component)
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
