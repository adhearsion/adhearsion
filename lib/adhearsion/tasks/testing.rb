# encoding: utf-8

begin
  require 'rspec/core/rake_task'
rescue LoadError
end

desc 'Run app tests, including components'
task :test => 'test:component'

desc 'Run app specs, including components'
task :spec => :test

namespace :test do
  desc "Run tests for a component specified by COMPONENT=<component_name>.  If no component is specified, tests will be executed for all components"
  task :component do
    component = ENV['COMPONENT']
    components_to_test = component.nil? ? all_component_directories : [full_path_for(component)]
    components_to_test.each do |component_name|
      setup_and_execute component_name
    end
  end

  private

    def setup_and_execute(component_path)
      task = create_test_task_for(component_path)
      Rake::Task[task.name].execute if task
    end

    def create_test_task_for(component_path)
      case task_type_for(component_path)
      when :test_unit
        Rake::TestTask.new task_name_for(component_path) do |t|
          t.libs = ["lib", "test"].map { |subdir| File.join component_path, subdir }
          t.test_files = FileList["#{component_path}/test/test_*.rb"]
          t.verbose = true
        end
      when :rspec
        if defined?(RSpec)
          RSpec::Core::RakeTask.new task_name_for(component_path) do |spec|
            spec.pattern = "#{component_path}/spec/**/*_spec.rb"
            spec.rspec_opts = '--color'
          end
        else
          puts "It looks like you have components with RSpec tests. You can run them by adding RSpec to your Gemfile."
        end
      end
    end

    def task_type_for(component_path)
      if Dir.exists?("#{component_path}/test")
        :test_unit
      elsif Dir.exists?("#{component_path}/spec")
        :rspec
      end
    end

    def task_name_for(component_path)
      "test_#{component_path.split(/\//).last}"
    end

    def all_component_directories
      Dir['components/*']
    end

    def full_path_for(component)
      component =~ /^components\// ? component : File.join("components", component)
    end
end