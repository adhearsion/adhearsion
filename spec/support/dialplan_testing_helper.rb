module DialplanTestingHelper
  def load(dial_plan_as_string)
    Adhearsion::DialPlan::Loader.load dial_plan_as_string
  end

  def mock_dialplan_with(string)
    string_io = StringIO.new(string)
    def string_io.path
      "dialplan.rb"
    end
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:files_from_setting).with("paths", "dialplan").and_return ["dialplan.rb"]
    flexstub(File).should_receive(:new).with("dialplan.rb").and_return string_io
    flexstub(File).should_receive(:read).with('dialplan.rb').and_return string
  end

  def new_manager_with_entry_points_loaded_from_dialplan_contexts
    Adhearsion::DialPlan::Manager.new.tap do |manager|
      manager.dial_plan.entry_points = manager.dial_plan.loader.load_dialplans.contexts
    end
  end

  def executing_dialplan(options)
    call         = options.delete(:call)
    context_name = options.keys.first
    dialplan     = options[context_name]
    call       ||= new_call_for_context context_name

    mock_dialplan_with dialplan

    lambda { Adhearsion::DialPlan::Manager.new.handle call }
  end

  def new_call_for_context(context)
    Adhearsion::Call.new(mock_offer).tap do |call|
      call.context = context
    end
  end

  def mock_dial_plan_lookup_for_context_name
    flexstub(Adhearsion::DialPlan).new_instances.should_receive(:lookup).with(context_name).and_return(mock_context)
  end
end
