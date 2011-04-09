require 'spec_helper'
require File.dirname(__FILE__) + "/../dsl/dispatcher_spec_helper"
require 'adhearsion/voip/freeswitch/oes_server'


describe "Adhearsion::VoIP::FreeSwitch::OesServer::OesDispatcher" do
  include StandardDispatcherBehavior
  before(:each) { @dispatcher_class = Adhearsion::VoIP::FreeSwitch::OesServer::OesDispatcher }
end