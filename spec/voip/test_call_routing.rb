require File.dirname(__FILE__) + '/../test_helper'

context "Call routing rule generation" do
  include CallRoutingTestHelper
  
  attr_reader :provider_one, :provider_two, :patterns

  setup do
    @provider_one = provider_named(:one)
    @provider_two = provider_named(:two)
    @patterns     = [/pattern/, /does not/, /matter/]
  end

  test "specifying a single pattern routed to a single provider properly stores that pattern and its provider in the generated route rule" do
    pattern = %r(does not matter)
    rule    = route(pattern, :to => provider_one)
    rule.patterns.should.equal [pattern]
    rule.providers.should.equal [provider_one]
  end

  test "specifying multiple patterns routed to a single provider stores all of them in the generated route rule" do
    first, second, third = patterns
    rule                 = route(first, second,  third, :to => provider_one)
    rule.patterns.should.equal [*patterns]
    rule.providers.should.equal [provider_one]
  end
  
  test "specifying multiple patterns routed to multiple providers stores all of them in the generated route rule, listing providers in the ordered specified" do
    first, second, third = patterns
    rule = route(first, second, third, :to => [provider_one, provider_two])
    rule.patterns.should.equal [*patterns]
    rule.providers.should.equal [provider_one, provider_two]
  end
end

context "Route calculation" do
  include CallRoutingTestHelper
  attr_reader :provider_one, :provider_two
  
  setup do
    rules.clear
    @provider_one = provider_named(:one)
    @provider_two = provider_named(:two)
  end
  
  test "Defining a rule adds it to the router rules" do
    provider = provider_one
    pattern  = /123/
    define_rules do
      route pattern, :to => provider
    end
    rules.size.should.equal 1
    rule = rules.first
    rule.providers.should.equal [provider]
    rule.patterns.should.equal [pattern]
  end
  
  test "Definiting multiple rules adds them to the router rules" do
    provider_for_rule_1 = provider_one
    provider_for_rule_2 = provider_two
    pattern_for_rule_1  = /123/
    pattern_for_rule_2  = /987/
    
    define_rules do
      route pattern_for_rule_1, :to => provider_for_rule_1
      route pattern_for_rule_2, :to => provider_for_rule_2
    end
    
    rules.size.should.equal 2
    
    rule_1 = rules.first
    rule_1.providers.should.equal [provider_for_rule_1]
    rule_1.patterns.should.equal [pattern_for_rule_1]
    
    rule_2 = rules.last
    rule_2.providers.should.equal [provider_for_rule_2]
    rule_2.patterns.should.equal [pattern_for_rule_2]
  end
  
  test "Provider is found in the simplest case of having only one pattern and one provider" do
    target_provider = provider_one
    define_rules do
      route /123/, :to => target_provider
    end
    calculate_route_for(1234).should.equal [target_provider]
  end
  
  test "Provider is found when the specified pattern matches a rule that is not the first rule" do
    provider_for_rule_1 = provider_one
    provider_for_rule_2 = provider_two
    pattern_for_rule_1  = /123/
    pattern_for_rule_2  = /987/
    
    define_rules do
      route pattern_for_rule_1, :to => provider_for_rule_1
      route pattern_for_rule_2, :to => provider_for_rule_2
    end
    
    target_provider = provider_for_rule_2
    calculate_route_for(9876).should.equal [target_provider]
  end
end

BEGIN {
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
}
