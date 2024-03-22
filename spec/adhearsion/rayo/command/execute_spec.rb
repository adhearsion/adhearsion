require "spec_helper"

module Adhearsion
  module Rayo
    module Command
      RSpec.describe Execute do
        it "registers itself" do
          command = Adhearsion::Rayo::RayoNode.class_from_registration(:exec, "urn:xmpp:rayo:1")

          expect(command).to eq(Execute)
        end

        it "is a server command" do
          command = Execute.new
          command.domain = "mydomain"
          command.target_call_id = SecureRandom.uuid

          expect(command).to have_attributes(
            domain: nil,
            target_call_id: nil
          )
        end

        describe ".from_xml" do
          it "initializes from xml" do
            stanza = <<-STANZA
              <exec xmlns="urn:xmpp:rayo:1" api="foo" args="bar baz"/>
            STANZA

            command = Adhearsion::Rayo::RayoNode.from_xml(parse_stanza(stanza).root)

            expect(command).to be_a(Execute)
            expect(command).to have_attributes(api: "foo", args: %w[bar baz])
          end
        end

        describe "#to_rayo" do
          it "serializes to Rayo XML" do
            command = Execute.new(api: "foo", args: %w[bar baz])

            rayo = command.to_rayo

            expect(rayo.name).to eq("exec")
            expect(rayo.attributes.fetch("api").value).to eq("foo")
            expect(rayo.attributes.fetch("args").value).to eq("bar baz")
          end
        end
      end
    end
  end
end
