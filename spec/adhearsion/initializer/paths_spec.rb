require 'spec_helper'

describe "Files from config" do

  it "should work when only one filename is present" do
    Adhearsion.config.ahnrc = "paths:\n    init: foobar.rb"

    flexmock(Adhearsion.config).should_receive(:files_from_glob).once.with("foobar.rb").and_return "foobar.rb"
    Adhearsion.config.files_from_setting("paths", "init").should == ["foobar.rb"]
  end

  it "should only expand a glob if the filename contains *"

  it "should work when an Array of filenames is present" do
    files = %w[jay.rb thomas.rb phillips.rb]
    flexstub(Dir).should_receive(:glob).with(*files).and_return(*files)
    yaml = <<-YML
paths:
  init:
#{
    files.map { |f| "    - #{f}" }.join("\n")
}
    YML
    Adhearsion.config.ahnrc = yaml

    flexmock(Adhearsion.config).should_receive(:files_from_glob).once.with("jay.rb").and_return "jay.rb"
    flexmock(Adhearsion.config).should_receive(:files_from_glob).once.with("thomas.rb").and_return "thomas.rb"
    flexmock(Adhearsion.config).should_receive(:files_from_glob).once.with("phillips.rb").and_return "phillips.rb"

    Adhearsion.config.files_from_setting("paths", "init").should == files
  end

  it "should work when one glob filename is present" do
    files = %w[foo.rb bar.rb qaz.rb]
    flexmock(Dir).should_receive(:glob).once.with(/\*.rb$/).and_return files
    yaml = <<-YML
    paths:
      init:
        -*.rb
    YML
    Adhearsion.config.ahnrc = yaml
    Adhearsion.config.files_from_setting("paths", "init").should == %w[foo.rb bar.rb qaz.rb]
  end

  it "should work when an Array of globs are present" do
    files = %w[aaa.rb aba.rb aca.rb]
    flexstub(Dir).should_receive(:glob).with(*files).and_return(*files)
    yaml = <<-YML
paths:
  init:
#{
    files.map { |filename| "    - #{filename}" }.join("\n") + "\n"
}
    YML
    Adhearsion.config.ahnrc = yaml
    files.each do |file|
      flexmock(Adhearsion.config).should_receive(:files_from_glob).once.with(file).and_return file
    end
    Adhearsion.config.files_from_setting("paths", "init").should == files
  end

end
