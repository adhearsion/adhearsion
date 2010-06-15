namespace :deprecations do
  desc <<-DESC
Older versions of Adhearsion had an .ahnrc "paths" section similar to the following...

  paths:
    models:
      directory: models
      pattern: *.rb

This has been deprecated. The new format is this:

  paths:
    models: {models,gui/app/models}/*.rb

This Rake task will fix your .ahnrc if you have
  DESC
  task :fix_ahnrc_path_format do
    puts "\nThis will remove all comments from your .ahnrc file. A backup will be created as .ahnrc.backup."
    puts "If you wish to do this manually to preserve your comments, simply overwrite .ahnrc with .ahnrc.backup"
    puts "and apply the change manually."
    puts

    require 'fileutils'
    require 'yaml'

    ahnrc_file = File.expand_path(".ahnrc")

    FileUtils.cp ahnrc_file, ahnrc_file + ".backup"
    ahnrc_contents = YAML.load_file ahnrc_file

    abort '.ahnrc does not have a "paths" section!' unless ahnrc_contents.has_key? "paths"

    paths = ahnrc_contents["paths"]
    paths.clone.each_pair do |key,value|
      if value.kind_of?(Hash)
        if value.has_key?("directory") || value.has_key?("pattern")
          directory, pattern = value.values_at "directory", "pattern"
          new_path = "#{directory}/#{pattern}"

          puts "!!! CHANGING KEY #{key.inspect}!"
          puts "!!! NEW: #{new_path.inspect}"
          puts "!!! OLD:\n#{{key => value}.to_yaml.sub("---", "")}\n\n"

          paths[key] = new_path
        end
      end
    end

    ahnrc_contents["paths"] = paths
    new_yaml = ahnrc_contents.to_yaml.gsub("--- \n", "")

    puts "New .ahnrc file:\n" + ("#" * 25) + "\n"
    puts new_yaml
    puts '#' * 25

    File.open(ahnrc_file, "w") { |file| file.puts new_yaml }
    puts "Wrote to .ahnrc. Done!"
  end
end