require File.dirname(__FILE__) + "/test_helper.rb"

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
