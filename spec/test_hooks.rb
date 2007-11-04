require 'test_helper'

context "Adhearsion::Hooks::TearDown when initializing a project" do
  include InitializerStubs
  test "should trap TERM and INT signals" do
    flexmock(Adhearsion::Hooks::TearDown).should_receive(:catch_termination_signals).at_least.once
    with_new_initializer_with_no_path_changing_behavior {}
  end
end

module StandardHookBehavior
  def test_standard_hook_behavior
    @hook.should.respond_to(:trigger_hooks)
    @hook.should.respond_to(:create_hook)
  end
end

for hook in Adhearsion::Hooks.constants.map { |c| (Adhearsion::Hooks.const_get c) }
  describe hook.to_s do
    include StandardHookBehavior
    before(:each) { @hook = hook }
  end
end
