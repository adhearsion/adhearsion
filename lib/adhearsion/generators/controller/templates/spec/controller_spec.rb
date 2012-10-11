# encoding: utf-8

describe <%= @controller_name.camelcase %> do

  let(:mock_call) { mock 'Call', :to => '1112223333', :from => "2223334444" }
  let(:metadata) { {} }
  subject { <%= @controller_name.camelcase %>.new(mock_call, metadata) }

  it "should have empty metadata" do
    subject.metadata.should eq({})
  end

end
