require 'spec_helper'

module CallRoutingTestHelper
  private
    def route(*args, &block)
      Adhearsion::VoIP::CallRouting::Rule.new(*args, &block)
    end

    def provider_named(name)
      Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new(name)
    end

    def define_rules(&block)
      Adhearsion::VoIP::CallRouting::Router.define(&block)
    end

    def calculate_route_for(end_point)
      Adhearsion::VoIP::CallRouting::Router.calculate_route_for(end_point)
    end

    def rules
      Adhearsion::VoIP::CallRouting::Router.rules
    end
end

describe "Call routing rule generation" do
  include CallRoutingTestHelper

  attr_reader :provider_one, :provider_two, :patterns

  before(:each) do
    @provider_one = provider_named(:one)
    @provider_two = provider_named(:two)
    @patterns     = [/pattern/, /does not/, /matter/]
  end

  it "specifying a single pattern routed to a single provider properly stores that pattern and its provider in the generated route rule" do
    pattern = %r(does not matter)
    rule    = route(pattern, :to => provider_one)
    rule.patterns.should == [pattern]
    rule.providers.should == [provider_one]
  end

  it "specifying multiple patterns routed to a single provider stores all of them in the generated route rule" do
    first, second, third = patterns
    rule                 = route(first, second,  third, :to => provider_one)
    rule.patterns.should == [*patterns]
    rule.providers.should == [provider_one]
  end

  it "specifying multiple patterns routed to multiple providers stores all of them in the generated route rule, listing providers in the ordered specified" do
    first, second, third = patterns
    rule = route(first, second, third, :to => [provider_one, provider_two])
    rule.patterns.should == [*patterns]
    rule.providers.should == [provider_one, provider_two]
  end
end

describe "Route calculation" do
  include CallRoutingTestHelper
  attr_reader :provider_one, :provider_two

  before(:each) do
    rules.clear
    @provider_one = provider_named(:one)
    @provider_two = provider_named(:two)
  end

  it "Defining a rule adds it to the router rules" do
    provider = provider_one
    pattern  = /123/
    define_rules do
      route pattern, :to => provider
    end
    rules.size.should be 1
    rule = rules.first
    rule.providers.should == [provider]
    rule.patterns.should == [pattern]
  end

  it "Definiting multiple rules adds them to the router rules" do
    provider_for_rule_1 = provider_one
    provider_for_rule_2 = provider_two
    pattern_for_rule_1  = /123/
    pattern_for_rule_2  = /987/

    define_rules do
      route pattern_for_rule_1, :to => provider_for_rule_1
      route pattern_for_rule_2, :to => provider_for_rule_2
    end

    rules.size.should be 2

    rule_1 = rules.first
    rule_1.providers.should == [provider_for_rule_1]
    rule_1.patterns.should == [pattern_for_rule_1]

    rule_2 = rules.last
    rule_2.providers.should == [provider_for_rule_2]
    rule_2.patterns.should == [pattern_for_rule_2]
  end

  it "Provider is found in the simplest case of having only one pattern and one provider" do
    target_provider = provider_one
    define_rules do
      route /123/, :to => target_provider
    end
    calculate_route_for(1234).should == [target_provider]
  end

  it "Provider is found when the specified pattern matches a rule that is not the first rule" do
    provider_for_rule_1 = provider_one
    provider_for_rule_2 = provider_two
    pattern_for_rule_1  = /123/
    pattern_for_rule_2  = /987/

    define_rules do
      route pattern_for_rule_1, :to => provider_for_rule_1
      route pattern_for_rule_2, :to => provider_for_rule_2
    end

    target_provider = provider_for_rule_2
    calculate_route_for(9876).should == [target_provider]
  end
end
