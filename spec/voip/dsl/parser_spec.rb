require 'spec_helper'

require 'adhearsion/voip/dsl/dialplan/parser'

describe "The Adhearsion VoIP dialplan parser" do

  it "should return a list of dialplans properly from dialplan code" do
    file = "foobar.rb"
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).once.with("paths", "dialplan").and_return [file]

    flexmock(File).should_receive(:exists?).with(file).and_return true
    flexmock(File).should_receive(:read).once.with(file).and_return <<-DIALPLAN
      internal {
        play "hello-world"
      }
      monkeys {
        play "tt-monkeys"
      }
    DIALPLAN
    contexts = Adhearsion::VoIP::DSL::Dialplan::DialplanParser.get_contexts
    contexts.keys.size.should be(2)
    contexts.keys.should include(:internal)
    contexts.keys.should include(:monkeys)
    contexts.each_pair do |context, struct|
      struct.should be_a_kind_of(OpenStruct)
      %w"file name block".each do |method|
        struct.should respond_to(method)
      end
    end
  end

  it "should warn when no dialplan paths were in the .ahnrc file" do
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).once.with("paths", "dialplan").and_return []
    flexmock(ahn_log.dialplan).should_receive(:warn).once.with(String)

    # Not loading it here is the same as it not existing in the "paths" sub-Hash
    Adhearsion::VoIP::DSL::Dialplan::DialplanParser.get_contexts
  end

end

describe "The Adhearsion VoIP dialplan interpreter" do

  it "should make dialplan contexts available within the context's block" do
    file = "contexts_from_code_helper_pseudo_dialplan.rb"
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).once.with("paths", "dialplan").and_return [file]

    flexmock(File).should_receive(:exists?).with(file).and_return true
    flexmock(File).should_receive(:read).with(file).and_return "foo { cool_method }"

    contexts = Adhearsion::VoIP::DSL::Dialplan::DialplanParser.get_contexts

    contexts.each_pair do |name, struct|
      contexts.meta_def(name) { struct.code }
    end

    # Simulate incoming request
    contexts = contexts.clone

    call_variables = { "callerid" => "14445556666", "context"  => "foo" }

    call_variables.each_pair do |key, value|
      contexts.meta_def(key) { value }
      contexts.instance_variable_set "@#{key}", value
    end

  end

end
