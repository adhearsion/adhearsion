# TODO: Does merb's plugins support using a custom repostiory?

require 'test_helper'

context "The helper generator" do
  test "should blow up if no helpers directory is referenced by .ahnrc"
  test "should create a directory in the first helpers directory from .ahnrc"
  test "should print instructions after generating the helper"
end

context "The helper installer system in general" do
  test "should use the Adhearsion.com repository"
  test "should ask to update when told to install an already-installed helper"
  test "should find the proper path of an installed helper"
  test "should properly reflect installed helpers with plugin_installed?()"
  test "should run the install script after a helper is installed"
  test "should add a helper's files to the manifest file after installing"
  test "should remove a helper's files from the helper manifest file"
  test "should install any dependant helpers from RubyGems"
  test "should install any dependant helpers from Subversion"
  test "should install any dependant gems from RubyForge"
end

context "The helper-related CLI commands" do
  test "should list files from the manifest file"
end

context "The RubyGems-based helper installer" do
  test "should unpack the gems when they're installed"
  test "should install the gems into the Adhearsion directory"
end

context "The Subversion-based helper installer" do
  test "should raise an error when the 'svn' command cannot be found"
  test "should checkout the code from the given repository into the appropriate directory"
  test "should keep the Subversion metadata"
  test "should issue a Subversion update when updating a helper"
end

context "The helper loader system in general" do
  test "should check <SOMETHING> for gem installation status"
  test "should only load enabled gems"
end

context "The helper .gem file loader" do
  test "should unpack a .gem file to a temporary location"
  test "should run the initialization script if one exists"
end

context "A helper's Rakefile" do
  test "should be loaded by the Adhearsion app's Rakefile"
end

# test "should load folders in the helpers folder referenced by .ahnrc"