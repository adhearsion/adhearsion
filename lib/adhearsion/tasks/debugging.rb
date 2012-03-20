# encoding: utf-8

task :debugging => :environment do
  initializer = Adhearsion::Initializer.new
  puts
  puts "Some info about your application environment:"
  puts initializer.debugging_items.join("\n\n")
end