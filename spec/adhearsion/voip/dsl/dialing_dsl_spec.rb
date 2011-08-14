require 'spec_helper'
require 'adhearsion/voip/dsl/dialing_dsl'

# Keep the monkey patches in a module and load that into Regexp
# eigenclasses during a before(:all) block?

describe "RouteRule Regexp assembling" do

  it "should compile two Regexps" do
    first, last = /jay/, /phillips/
    r = first | last
    r.patterns.should == [first, last]
  end

  it "should compile three or more Regexps" do
    first, second, third = /lorem/, /ipsum/, /dolar/
    r = first | second | third
    r.patterns.should == [first, second, third]
  end

end

describe "RouteRule assembling with one provider definition" do

  before :each do
    @provider = Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new(:icanhascheezburger?)
  end

  it "should store one pattern properly" do
    pattern = /lorem/
    route = pattern >> @provider
    route.patterns.should == [pattern]
  end

  it "should store three patterns properly" do
    first, second, third = /lorem/, /ipsum/, /dolar/
    route = first | second | third >> @provider
    route.patterns.should == [first, second, third]
    route.providers.should == [@provider]
  end

end

describe "RouteRule assembling with multiple patterns and multiple provider definitions" do

  before(:each) do
    1.upto 3 do |i|
      instance_variable_set "@prov_#{i}",
        Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new("prov_#{i}")
      instance_variable_set "@pattern_#{i}", /^#{i * 100}$/
    end
  end

  it "should store the patterns properly" do
    route_1 = @pattern_1 | @pattern_2 | @pattern_3 >> @prov_1 >> @prov_2 >> @prov_3
    route_1.patterns.should == [@pattern_1, @pattern_2, @pattern_3]

    route_2 = @pattern_2 | @pattern_3 | @pattern_1 >> @prov_3 >> @prov_2 >> @prov_1
    route_2.patterns.should == [@pattern_2, @pattern_3, @pattern_1]
  end

  it "should store the providers properly" do
    route_1 = @pattern_1 | @pattern_2 | @pattern_3 >> @prov_1 >> @prov_2 >> @prov_3
    route_1.providers.should == [@prov_1, @prov_2, @prov_3]

    route_2 = @pattern_2 | @pattern_3 | @pattern_1 >> @prov_3 >> @prov_2 >> @prov_1
    route_2.patterns.should == [@pattern_2, @pattern_3, @pattern_1]
  end
end

describe "The DialingDSL class internals" do

  it "should allow Asterisk-like patterns" do
    Adhearsion::VoIP::DSL::DialingDSL.class_eval do
      _('23XX')
    end.should be_an_instance_of Regexp
  end

  it "should define all of the VoIP constants" do
    lambda do
      Adhearsion::VoIP::Constants.constants.each do |constant|
        eval "Adhearsion::VoIP::DSL::DialingDSL::#{constant}"
      end
    end.should_not raise_error NameError
  end

  # it "should define a DUNDI constant"

  it "should synchronize access to the trunking information for Thread safety"

end

describe "The provider DSL's 'provider' macro" do

  it "should make the providers available in the order they were received" do
    provider_holder = Class.new Adhearsion::VoIP::DSL::DialingDSL
    provider_holder.class_eval do
      provider(:tweedledee) {}
      provider(:tweedledum) {}
    end
    provider_holder.providers.map { |x| x.name }.should == [:tweedledee, :tweedledum]
  end
  it "should define a singleton method for the provider name given" do
    dsl_class = Class.new(Adhearsion::VoIP::DSL::DialingDSL)
    dsl_class.class_eval do
      class_variable_get(:@@providers).size.should == 0

      provider(:icanhascheezburger?) {}

      class_variable_get(:@@providers).size.should == 1
    end
    dsl_class.should respond_to(:icanhascheezburger?)
  end
  it "should not define a class-wide method for the provider name given" do
    dsl_class = Class.new(Adhearsion::VoIP::DSL::DialingDSL)
    dsl_class.class_eval do
      provider(:icanhascheezburger?) {}
    end
    Adhearsion::VoIP::DSL::DialingDSL.class_eval do
      class_variable_defined?(:@@providers).should == false
    end
    Adhearsion::VoIP::DSL::DialingDSL.should_not respond_to(:icanhascheezburger?)
  end
  it "should yield a ProviderDefinition object" do
    possible_provider_definition = nil
    Class.new(Adhearsion::VoIP::DSL::DialingDSL).class_eval do
      provider(:blah) { |pd| possible_provider_definition = pd }
    end
    possible_provider_definition.should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition)
  end
  it "should raise an error when no block is given" do
    the_following_code do
      Class.new(Adhearsion::VoIP::DSL::DialingDSL).class_eval do
        provider :explode
      end
    end.should raise_error ArgumentError
  end
end

describe "The provider DSL's monkey patches to Regexp" do
  it "should return a RouteRule when using Regexp#| with another Regexp" do
    (// | //).should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::RouteRule)
  end
  it "should return a RouteRule when chaining three Regexp's with the | operator" do
    (// | // | //).should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::RouteRule)
  end
  it "should return a RouteRule when Regexp#| is given a RouteRule" do
    route_rule = Adhearsion::VoIP::DSL::DialingDSL::RouteRule.new :patterns => //
    (// | route_rule).should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::RouteRule)
  end
  it "should return a RouteRule when Regexp#>> is given a ProviderDefinition" do
    (/1/ >> Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new(:foo)).
      should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::RouteRule)
  end
  it "should return a RouteRule when Regexp#>>() receives a ProviderDefinition" do
    definition = Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new(:london)
    (/foo/ >> definition).should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::RouteRule)
  end
  it "should raise an exception when Regexp#| receives something other than a RouteRule" do
    bad_args = [ 0..100, 20, 45.55, {}, [] ]
    bad_args.each do |arg|
      the_following_code { /foo/ | arg }.should raise_error ArgumentError
    end
  end
  it "should raise an exception when Regexp#>>() receives anything other than a ProviderDefintion or RouteRule" do
    bad_args = [ 0..100, 20, 45.55, {}, [] ]
    bad_args.each do |arg|
      the_following_code { /foo/ >> arg }.should raise_error ArgumentError
    end
  end
end

describe "A RouteRule" do
  it "should expose chained ProviderDefinitions properly" do
    one, two, three = definitions = %w"foo bar qaz".map do |name|
      Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new name
    end
    route = /^911$/ >> one >> two >> three
    route.should be_a_kind_of(Adhearsion::VoIP::DSL::DialingDSL::RouteRule)
    route.providers.should == definitions
  end
  it "should define attr_readers for providers and patterns" do
    route = Adhearsion::VoIP::DSL::DialingDSL::RouteRule.new
    route.should respond_to(:patterns)
    route.should respond_to(:providers)
  end
end

describe "The provider order modifiers" do
   it "should support randomizing trunks", :ignore => true do
    dsl = Class.new Adhearsion::VoIP::DSL::DialingDSL
    dsl.class_eval do
      provider(:l33thost) {}
      provider(:h4xxhost) {}
      route /\d+\*548/ >> random(l33thost, h4xxhost)
    end
    dsl.routes.first.provider_definitions.first.should be_a_kind_of(
      Adhearsion::VoIP::DSL::DialingDSL::RandomRouteRule
    )
  end
end

describe "The provider DSL's 'route' builder" do
  it "should register routes in the order received" do
    dsl = Class.new Adhearsion::VoIP::DSL::DialingDSL
    dsl.class_eval do
      provider(:kewlphone) {}
      [/1?4445556666/, /123/, /\d+\*548/].each do |r|
        route r >> kewlphone
      end
    end
    dsl.routes.map { |x| x.patterns }.flatten.should == [/1?4445556666/, /123/, /\d+\*548/]
  end
end

describe "A ProviderDefinition" do
  it "should store any arbitrary property" do
    definition = Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new :foo
    definition.qaz = :something
    definition.qaz.should == :something
  end
  it "should define a >>() method" do
    Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new(:arghh).should respond_to(:>>)
  end

  it "should format numbers properly" do
    definition = Adhearsion::VoIP::DSL::DialingDSL::ProviderDefinition.new(:arghh)
    definition.protocol = "SIP"
    definition.format_number_for_platform("14445556666", :asterisk).should == "SIP/arghh/14445556666"
    definition.protocol = "SCCP"
    definition.format_number_for_platform("16663331111", :asterisk).should == "SCCP/arghh/16663331111"

  end
end

describe "Routing with the interpreted route definitions" do
  it "should use the first matching regular expression" do
    dsl = Class.new Adhearsion::VoIP::DSL::DialingDSL
    dsl.class_eval do
      provider(:bad)  {}
      provider(:good) {}
      route /^111$/ | /^222$/ | /^333$/ >> good >> bad
    end

    found = dsl.calculate_routes_for(333)

    1.should be found.size
    found.first.size.should be 2
  end

end

# @example = Class.new Adhearsion::VoIP::DSL::DialingDSL
# @example.class_eval do
#
#   provider:kewlphone do |trunk|
#     trunk.protocol :sip
#     trunk.host     "voip.nufone.com"
#     trunk.username "phonedude"
#     trunk.password "secret"
#     trunk.enters   :internal
#   end
#
#   route US_NUMBER | US_LOCAL_NUMBER >> voip_ms >> nufone
#
#   route INTL_NUMBER >> random(voip_ms, nufone)
#
#   # route _('NXX') >> DUNDI
#
# end
