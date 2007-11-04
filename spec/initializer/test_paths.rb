require File.dirname(__FILE__) + "/../test_helper"

describe "Adhearsion::Paths" do
  
  #TODO: All this crap will go away
  disabled_test "should find all files when given a glob" do
    inside_initialized_app do |path|
      tmps = %w"foo.rb BA\ R.gem _q_a_z_.c"
      tmps.each { |f| FileUtils.touch "#{path}/helpers/#{f}" }
      found_helpers = all_helpers
      all_helpers.should.not.be.empty
      all_helpers.map! {|f| File.basename f }
      all_helpers.each { |f| all_helpers.should.include(f) }
    end
  end
  test "should find files when several globs are given"

  test "should allow the removal of path managers" do
    Adhearsion::Paths.manager_for :helpers, :directory => "helpers"
    Adhearsion::Paths.remove_manager_for :helpers
  end
end

describe "The .ahnrc " do
  test "should allow ERb"
  test "should create methods for every path declared"
  test "should add all_x and x_path methods to main namespace and pluralize names" do
    Adhearsion::Paths.manager_for "helper", :directory => "helpers"
    should.respond_to(:all_helpers)
    should.respond_to(:helper_path)
  end
  test "should have an init key"
  test "should allow a String to the init key"
  test "should default the init key to config/startup.rb"
  test "should allow an Array to the init key"
end

describe "Adhearsion's paths syntax sugar" do
  test "should calculate helper paths properly"
  test "should find log files properly"
  test "should find helper config paths properly"
  test "should return the configuration for a helper properly"
end