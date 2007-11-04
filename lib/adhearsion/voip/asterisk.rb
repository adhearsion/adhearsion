%w[/dsl/numerical_string /asterisk/agi_server /asterisk/commands].each do |asterisk_code_file|
  require File.dirname(__FILE__) + asterisk_code_file
end