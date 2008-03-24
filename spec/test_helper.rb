Dir.chdir File.join(File.dirname(__FILE__), '..')
require 'rubygems'
def require_or_report_dependency(require_name, gem_name)
  begin
    require require_name
  rescue LoadError 
    report_dependency!(gem_name)
  end
end

def report_dependency!(name)
  puts;puts 
  puts "You need #{name} to run these tests:  gem install #{name}"
  puts;puts
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
class Adhearsion::Initializer
  def asterisk_enabled?
    false
  end
end




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
  
  UNWANTED_BEHAVIOR = {
    Adhearsion::Initializer                       => [:initialize_log_file, :switch_to_root_directory, :daemonize!],
    Adhearsion::Hooks::AfterInitialized.metaclass => [:create_hook, :trigger_hooks]
  } unless defined? UNWANTED_BEHAVIOR
  
  def with_new_initializer_with_no_path_changing_behavior
    stub_unwanted_behavior
    Adhearsion::Initializer.new('path does not matter')
    yield if block_given?
    unstub_directory_changing_behavior
  end
  
  def stub_unwanted_behavior
    UNWANTED_BEHAVIOR.each do |stub_victim_class, undesired_methods|
      undesired_methods.each do |undesired_method_name|
        stub_victim_class.send(:alias_method, "pre_stubbed_#{undesired_method_name}", undesired_method_name)
        stub_victim_class.send(:define_method, undesired_method_name) { |*args| }
      end
    end
  end
  
  def unstub_directory_changing_behavior
    UNWANTED_BEHAVIOR.each do |stub_victim_class, undesired_methods|
      undesired_methods.each do |undesired_method_name|
        stub_victim_class.send(:alias_method, undesired_method_name, "pre_stubbed_#{undesired_method_name}")
      end
    end
  end
end

Adhearsion::Initializer.ahn_root = File.dirname(__FILE__) + '/fixtures'
require 'spec/silence' unless ENV['SHOW_DISABLED']

require 'adhearsion/voip/asterisk'
require 'adhearsion/component_manager'
