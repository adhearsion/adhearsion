namespace:components do
  desc "Install component configuration from templates"
  task :genconfig do
    init = Adhearsion::Initializer.new(Rake.original_dir)
    init.bootstrap_rc
    init.load_all_init_files
    Adhearsion::AHN_CONFIG.components_to_load.each do |component|
      spec = Gem.searcher.find(component)
      if spec.nil?
        abort "ERROR: Required gem component #{component} not found."
      end

      yml = File.join(spec.full_gem_path, 'config', "#{component}.yml")
      target = File.join(AHN_ROOT, 'config', 'components', "#{component}.yml")
      Dir.mkdir(File.dirname(target)) if !File.exists?(File.dirname(target))
      if File.exists?(target)
        puts "Skipping existing configuration for component #{component}"
        next
      end
      if File.exists?(yml)
        begin
          FileUtils.cp(yml, target)
          puts "Installed default configuration for component #{component}"
        rescue => e
          abort "Error copying configuration for component #{component}: #{e.message}"
        end
      else
        puts "No template configuration found for component #{component}"
      end
    end
  end
end
