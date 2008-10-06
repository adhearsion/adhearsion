require File.dirname(__FILE__) + "/../test_helper"

context "Files from config" do
  
  include PathsTestHelper
  
  test "the old way of doing paths should not still be around" do
    should.not.respond_to(:all_helpers)
    should.not.respond_to(:helper_path)
  end
  
  test "should work when only one filename is present" do
    mock_ahnrc_with "paths:\n    init: foobar.rb"
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_glob).once.with("foobar.rb").and_return "foobar.rb"
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql ["foobar.rb"]
  end
  
  test "should work when an Array of filenames is present" do
    yaml = <<-YML
paths:
  init:
    - foo.rb
    - bar.rb
    - qaz.rb
    YML
    Adhearsion::AHN_CONFIG.ahnrc = yaml
    
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_glob).once.with("foo.rb").and_return "foo.rb"
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_glob).once.with("bar.rb").and_return "bar.rb"
    flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_glob).once.with("qaz.rb").and_return "qaz.rb"
    
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql(%w[foo.rb bar.rb qaz.rb])
  end
  
  test "should work when one glob filename is present" do
    files = %w[foo.rb bar.rb qaz.rb]
    flexmock(Dir).should_receive(:glob).once.with(/\*.rb$/).and_return files
    yaml = <<-YML
    paths:
      init: *.rb
    YML
    Adhearsion::AHN_CONFIG.ahnrc = yaml
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql(%w[foo.rb bar.rb qaz.rb])
  end
    
  test "should work when an Array of globs are present" do
    files = %w[aaa.rb aba.rb aca.rb]
    yaml = <<-YML
paths:
  init:
#{
    files.map { |filename| "    - #{filename}" }.join("\n") + "\n"
}
    YML
    Adhearsion::AHN_CONFIG.ahnrc = yaml
    files.each do |file|
      flexmock(Adhearsion::AHN_CONFIG).should_receive(:files_from_glob).once.with(file).and_return file
    end
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql(files)
  end
  
end

BEGIN {
  module PathsTestHelper
    def mock_ahnrc_with(raw_yaml)
      Adhearsion::AHN_CONFIG.ahnrc = YAML.load raw_yaml
    end
  end
}