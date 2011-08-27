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
end
