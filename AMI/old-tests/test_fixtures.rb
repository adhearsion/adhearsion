require File.dirname(__FILE__) + "/ami_helper"

context "The fixture searching logic" do
  it "should properly travel a path through the YAML and return a String" do
    fixture("login/standard/client").should.be.kind_of String
  end
  
  it "should properly extract template fixture values and define them as singleton methods" do
    standard_login = fixture("login/standard/client")
    standard_login.secret.should.be.kind_of String
    %w[on off].should.include(standard_login.events)
  end
  
end

context "Converting a fixture to an AMI stanza" do
  
  it "should put a Response: header at the beginning" do
    fixture("login/standard/fail").downcase.starts_with?("response:").should.equal true
  end
  
  it "should put an Action: header at the beginning" do
    fixture("login/standard/client").downcase.starts_with?("action:").should.equal true
  end
  
end