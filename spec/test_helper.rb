Dir.chdir File.join(File.dirname(__FILE__), '..')

require 'rubygems'
require 'bundler/setup'

# Use Turn if we have it
begin; require 'turn'; rescue LoadError; end

def require_or_report_dependency(require_name, gem_name)
  begin
    require require_name
  rescue LoadError
    report_dependency!(gem_name)
  end
end

def report_dependency!(name)
  2.times { puts }
  puts "You need #{name} to run these tests:  gem install #{name}"
  2.times { puts }
  exit!
end

require_or_report_dependency('test/spec', 'test-spec')
require_or_report_dependency('flexmock/test_unit', 'flexmock')
require_or_report_dependency('active_support', 'activesupport')
# require_or_report_dependency('ruby-debug', 'ruby-debug')
require_or_report_dependency('rubigen', 'rubigen')

require 'pp'
require 'stringio'

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$: << File.expand_path('lib')
$: << File.dirname(__FILE__)

require 'adhearsion'

class Test::Unit::TestCase

  alias_method :the_following_code, :lambda
  def self.test(*args, &block)
    if block_given?
      specify(args, &block)
    else
      disabled_test(*args)
    end
  end

  def self.disabled_test(*args, &block)
    xspecify(*args, &block)
  end

end

module InitializerStubs

  DEFAULT_AHNRC_DATA_STRUCTURE = YAML.load_file(
    File.dirname(__FILE__) + "/../app_generators/ahn/templates/.ahnrc"
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
            [undesired_method_name_or_key_value_pair.first, lambda { undesired_method_name_or_key_value_pair.last } ]
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

Adhearsion::Initializer.ahn_root = File.dirname(__FILE__) + '/fixtures'
require 'spec/silence' unless ENV['SHOW_DISABLED']

require 'adhearsion/voip/asterisk'
require 'adhearsion/component_manager'
