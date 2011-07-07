require 'spec_helper'

describe "Example" do

  it "should properly load the YAML in a file" do
    example_name = :kewlz0rz
    data_structure = {:foo => :bar, :qaz => [1,2,3,4,5]}
    yaml = data_structure.to_yaml
    file_contents = <<-FILE
# Some comment here
=begin YAML
#{yaml}
=end
events.blah.each { |event| }
events.blah2.each { |event| }

# More comments
=begin
another block
=end
    FILE

    flexmock(File).should_receive(:read).once.with(/kewlz0rz\.rb$/).and_return file_contents
    example = Example.new(example_name)
    example.metadata.should == data_structure
  end

end