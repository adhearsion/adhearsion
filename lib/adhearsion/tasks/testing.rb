namespace:test do
  desc "Run tests for a component specified by COMPONENT=<component_name>.  If no component is specified, tests will be executed for all components"
  task :component do
    component = ENV['COMPONENT']
    components_to_test = component.nil? ? all_component_directories : [full_path_for(component)]
    components_to_test.each do |component_name|
      setup_and_execute(component_name)
    end
  end
  
  private  
  
    def setup_and_execute(component_path)
      task = create_test_task_for(component_path)
      Rake::Task[task.name].execute
    end
    
    def create_test_task_for(component_path)
      Rake::TestTask.new(task_name_for(component_path)) do |t|
         t.libs = ["lib", "test"].map{|subdir| File.join(component_path, subdir)}
         t.test_files = FileList["#{component_path}/test/test_*.rb"]
         t.verbose = true
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