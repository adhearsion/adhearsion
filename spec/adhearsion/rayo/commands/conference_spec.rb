require 'spec_helper'

module Adhearsion
  module Rayo
    module Commands
      describe Conference do
        include RayoCommandTestHelpers

        describe "#conference" do
          let(:conference_id) { 'abc123' }
          let(:options)       { { :mute => true } }

          it 'executes a Conference with the correct options' do
            expect_component_execution Punchblock::Component::Tropo::Conference.new(options.merge(:name => conference_id))
            mock_execution_environment.conference(conference_id, options).should be true
          end
        end
      end
    end
  end
end
