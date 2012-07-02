# encoding: utf-8

require 'tempfile'
stderr_file = Tempfile.new "ahn#{rand}.stderr"
warnings_filename = "tmp/ahnwarnings#{rand}.txt"
$stderr.reopen stderr_file.path
current_dir = Dir.pwd

at_exit do
  begin
    stderr_file.rewind
    lines = stderr_file.read.split("\n").uniq
    stderr_file.close!

    ahn_warnings, other_warnings = lines.partition { |line| line.include?(current_dir) && !line.include?('vendor') && line.include?('warning') }

    if ahn_warnings.any?
      puts
      puts "-" * 30 + " AHN Warnings: " + "-" * 30
      puts
      puts ahn_warnings.join("\n")
      puts
      puts "-" * 75
      puts
    end

    if other_warnings.any?
      File.open(warnings_filename, 'w') { |f| f.write other_warnings.join("\n") }
      puts
      puts "Non-AHN warnings written to #{warnings_filename}"
      puts
    end

    exit 1 if ahn_warnings.any? # fail the build...
  rescue => e
    puts "Warning capture failed."
    puts e.message
    puts e.backtrace.join("\n")
  end
end
