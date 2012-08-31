# encoding: utf-8

describe <%= @controller_name %> do

  let(:mock_call) { mock 'Call', :to => '1112223333', :from => "2223334444" }
  let(:metadata) { {} }
  subject { <%= @controller_name %>.new(mock_call, metadata) }

  after { subject.run }

  it "should have empty metadata" do
    subject.metadata.should eq({})
  end

end
