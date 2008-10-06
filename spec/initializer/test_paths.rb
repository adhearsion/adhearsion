require File.dirname(__FILE__) + "/../test_helper"

context "Files from config" do
  
  include PathsTestHelper
  
  test "the old way of doing paths should not still be around" do
    should.not.respond_to(:all_helpers)
    should.not.respond_to(:helper_path)
  end
  
  test "should work when only one filename is present" do
    filename = "startup.rb"
    mock_ahnrc_with "paths:\n    init: #{filename}"
    flexstub(Dir).should_receive(:glob).once.with(filename).and_return(filename)
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql([filename])
  end
  
  test "should only expand a glob if the filename contains *"
  
  test "should work when an Array of filenames is present" do
    files = %w[jay.rb thomas.rb phillips.rb]
    flexstub(Dir).should_receive(:glob).with(*files).and_return(*files)
    yaml = <<-YML
paths:
  init:
#{
    files.map { |f| "    - #{f}\n" }
}
    YML
    mock_ahnrc_with yaml
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql(files)
  end
  
  test "should work when one glob filename is present" do
    files = %w[foo.rb bar.rb qaz.rb]
    flexstub(Dir).should_receive(:glob).with("*.rb").and_return files
    yaml = <<-YML
    paths:
      init: *.rb
    YML
    mock_ahnrc_with yaml
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql(files)
  end
    
  test "should work when an Array of globs are present" do
    files = %w[aaa.rb aba.rb aca.rb]
    flexstub(Dir).should_receive(:glob).with(*files).and_return(*files)
    yaml = <<-YML
paths:
  init:
#{
    files.map { |f| "    - #{f}\n" }
}
    YML
    mock_ahnrc_with yaml
    Adhearsion::AHN_CONFIG.files_from_setting("paths", "init").should.eql(files)
  end
  
end

BEGIN {
  module PathsTestHelper
    def mock_ahnrc_with(raw_yaml)
      Adhearsion::AHN_CONFIG.ahnrc = raw_yaml
    end
  end
}