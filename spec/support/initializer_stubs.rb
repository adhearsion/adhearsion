module InitializerStubs
  DEFAULT_AHNRC_DATA_STRUCTURE = YAML.load_file(
    File.dirname(__FILE__) + "/../../app_generators/ahn/templates/.ahnrc"
  ) unless defined? DEFAULT_AHNRC_DATA_STRUCTURE

  UNWANTED_BEHAVIOR = {
    Adhearsion::Initializer => [:initialize_log_file, :switch_to_root_directory, :daemonize!, :load],
    Adhearsion::Initializer.metaclass => { :get_rules_from => DEFAULT_AHNRC_DATA_STRUCTURE },
  } unless defined? UNWANTED_BEHAVIOR

  def stub_behavior_for_initializer_with_no_path_changing_behavior
      stub_unwanted_behavior
      yield if block_given?
    ensure
      unstub_directory_changing_behavior
  end

  def with_new_initializer_with_no_path_changing_behavior(&block)
    stub_behavior_for_initializer_with_no_path_changing_behavior do
      block.call Adhearsion::Initializer.start('path does not matter')
    end
  end

  def stub_unwanted_behavior
    UNWANTED_BEHAVIOR.each do |stub_victim_class, undesired_methods|
      undesired_methods.each do |undesired_method_name_or_key_value_pair|
        undesired_method_name, method_implementation = case undesired_method_name_or_key_value_pair
          when Array
            [undesired_method_name_or_key_value_pair.first, lambda { |*args| undesired_method_name_or_key_value_pair.last } ]
          else
            [undesired_method_name_or_key_value_pair, lambda{ |*args| }]
        end
        stub_victim_class.send(:alias_method, "pre_stubbed_#{undesired_method_name}", undesired_method_name)
        stub_victim_class.send(:define_method, undesired_method_name, &method_implementation)
      end
    end
  end

  def unstub_directory_changing_behavior
    UNWANTED_BEHAVIOR.each do |stub_victim_class, undesired_methods|
      undesired_methods.each do |undesired_method_name|
        undesired_method_name = undesired_method_name.first if undesired_method_name.kind_of? Array
        stub_victim_class.send(:alias_method, undesired_method_name, "pre_stubbed_#{undesired_method_name}")
      end
    end
  end
end
