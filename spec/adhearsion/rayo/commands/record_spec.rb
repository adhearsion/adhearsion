require 'spec_helper'

module Adhearsion
  module Rayo
    module Commands
      describe Record do
        include RayoCommandTestHelpers

        describe "#record" do
          let(:options) {{
            :start_beep => true,
            :format => 'mp3',
            :start_paused => false,
            :stop_beep => true,
            :max_duration => 500000,
            :initial_timeout => 10000,
            :final_timeout => 30000
          }}

          it 'executes a Record with the correct options' do
            expect_component_execution Punchblock::Component::Record.new(options)
            mock_execution_environment.record(options).should be true
          end
        end

      end
    end
  end
end
