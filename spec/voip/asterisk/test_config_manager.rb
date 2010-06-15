require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/asterisk/config_manager'

context "The configuration file parser behavior" do

  include ConfigurationManagerTestHelper

  test "should expose a sections array" do
    manager = mock_config_manager
    manager.sections.map(&:first).should.equal(["jicksta", "picard"])
  end

  test "should ignore comments" do
    context_names = %w(monkey data)
    tested_key_name, tested_key_value_before_comment = "bar", "baz"
    manager = mock_config_manager_for <<-CONFIG
[monkey]
#{tested_key_name}=#{tested_key_value_before_comment};thiscommentshouldnotbehere
asdf=fdsa
;[data]
;ignored=asdf
    CONFIG
    manager.sections.map(&:first).should.equal [context_names.first]
    manager[context_names.first].size.should.equal 2
    manager[context_names.first][tested_key_name].should.equal tested_key_value_before_comment
  end

  test "should match context names with dashes and underscores" do
    context_names = %w"foo-bar qaz_b-a-z"
    definition_string = <<-CONFIG
[#{context_names.first}]
platypus=no
zebra=no
crappyconfig=yes

[#{context_names.last}]
callerid="Jay Phillips" <133>
    CONFIG
    mock_config_manager_for(definition_string).sections.map(&:first).should.equal context_names
  end

  test "should strip whitespace around keys and values" do
    section_name = "hey-there-hot-momma"
    tested_key_name, tested_key_value_before_comment = "bar", "i heart white space. SIKE!"
    config_manager = mock_config_manager_for <<-CONFIG
   \t[#{section_name}]

   thereis            =  a lot of whitespace after these

    #{tested_key_name}   = \t\t\t #{tested_key_value_before_comment}

    CONFIG
    config_manager[section_name][tested_key_name].should.equal tested_key_value_before_comment
  end

  test "should return a Hash of properties when searching for an existing section" do
    result = mock_config_manager["jicksta"]
    result.should.be.kind_of Hash
    result.size.should.equal 3
  end

  test "should return nil when searching for a non-existant section" do
    mock_config_manager["i-so-dont-exist-dude"].should.be.nil
  end

end

context "The configuration file writer" do

  include ConfigurationManagerTestHelper

  attr_reader :config_manager

  setup do
    @config_manager = mock_config_manager
  end

  test "should remove an old section when replacing it" do
    config_manager.delete_section "picard"
    config_manager.sections.map(&:first).should.equal ["jicksta"]
  end

  test "should add a new section to the end" do
    section_name = "wittynamehere"
    config_manager.new_section(section_name, :type => "friend",
                                             :witty => "yes",
                                             :shaken => "yes",
                                             :stirred => "no")
    new_section = config_manager.sections.last
    new_section.first.should.equal section_name
    new_section.last.size.should.equal 4
  end
end

context "The configuration file generator" do
end

BEGIN {
module ConfigurationManagerTestHelper

  def mock_config_manager
    mock_config_manager_for sample_standard_config
  end

  def mock_config_manager_for(config_string)
    returning new_config_manager_with("bogus filename") do |manager|
      flexmock(manager).should_receive(:execute).and_return(config_string)
    end
  end

  def new_config_manager_with(filename)
    Adhearsion::VoIP::Asterisk::ConfigurationManager.new(filename)
  end

  def sample_standard_config
    <<-CONFIG
[jicksta]
foo=bar
qaz=qwerty
baz=zxcvb
[picard]
type=friend
insecure=very
host=dynamic
secret=blargh
    CONFIG
  end
end
}