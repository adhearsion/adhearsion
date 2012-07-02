# encoding: utf-8

desc "List the configured plugins"
task :plugins => :environment do |t,args|
  if Adhearsion::Plugin.subclasses.length > 0
    puts "You have #{Adhearsion::Plugin.subclasses.length} plugin(s) in your Adhearsion application:\n"
    Adhearsion::Plugin.subclasses.each do |plugin|
      puts "* #{plugin.plugin_name}: #{plugin.name}"
    end
  else
    puts "There is no Adhearsion plugin used in your application"
  end
  puts "\n"
end
