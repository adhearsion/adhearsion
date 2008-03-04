require File.dirname(__FILE__) + "/test_helper.rb"

# context "Adhearsion::Hooks::TearDown when initializing a project" do
#   include InitializerStubs
#   test "should trap TERM and INT signals" do
#     flexmock(Adhearsion::Hooks::TearDown).should_receive(:catch_termination_signals).at_least.once
#     with_new_initializer_with_no_path_changing_behavior {}
#   end
# end

# module StandardHookBehavior
#   def test_standard_hook_behavior
#     @hook.should.respond_to(:trigger_hooks)
#     @hook.should.respond_to(:create_hook)
#   end
# end

# for hook in Adhearsion::Hooks.constants.map { |c| (Adhearsion::Hooks.const_get c) }
#   describe hook.to_s do
#     include StandardHookBehavior
#     before(:each) { @hook = hook }
#   end
# end

context "A HookWithArguments" do
  test "should pass the arguments to trigger_hooks() along to each registered block" do
    hook_manager = Adhearsion::Hooks::HookWithArguments.new
    hook_manager.create_hook do |foo, bar|
      foo.should.equal :foo
      bar.should.equal :bar
      throw :inside_hook
    end
    the_following_code {
      hook_manager.trigger_hooks(:foo, :bar)
    }.should.throw :inside_hook
  end
end
