module RayoCommandTestHelpers
  include FlexMock::ArgumentTypes

  def self.included(test_case)
    test_case.let :mock_execution_environment do
      flexmock Object.new.tap { |ee| ee.extend Adhearsion::Rayo::Commands }, :call => mock_call
    end

    test_case.let :mock_call do
      flexmock :write_command => true
    end
  end

  def expect_message_waiting_for_response(message)
    mock_execution_environment.should_receive(:write_and_await_response).once.with(message).and_return(message)
  end

  def expect_component_execution(component)
    mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(component).and_return(component)
  end

  def expect_component_execution_asynchronously(component)
    mock_execution_environment.should_receive(:execute_component).once.with(component).and_return(component)
  end
end
