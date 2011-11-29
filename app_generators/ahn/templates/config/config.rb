require File.join(File.dirname(__FILE__), 'environment')

Adhearsion.config do |config|

end

Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")
