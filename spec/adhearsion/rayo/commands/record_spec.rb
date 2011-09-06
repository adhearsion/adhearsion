require 'spec_helper'

module Adhearsion
  module Rayo
    module Commands
      describe Record do
        include RayoCommandTestHelpers

        describe "#record" do
          let(:format) { 'mp3' }
          let(:options) { {:start_beep => true} }

          it 'executes a Record with plain text/string input' do
            expect_component_execution Punchblock::Component::Record.new(options.merge(:format => format))
            mock_execution_environment.record(format, options).should be true
          end
        end

      end
    end
  end
end
