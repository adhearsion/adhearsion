# encoding: utf-8

require 'ruby_ami'

def parse_stanza(xml)
  Nokogiri::XML.parse xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS
end

def import_stanza(xml)
  Blather::Stanza.import parse_stanza(xml).root
end

def stub_uuids(value)
  allow(RubyAMI).to receive_messages :new_uuid => value
  allow(Adhearsion).to receive_messages :new_uuid => value
end

# FIXME: change this to rayo_event?  It can be ambigous
shared_examples_for 'event' do
  describe '#target_call_id' do
    subject { super().target_call_id }
    it { is_expected.to eq('9f00061') }
  end

  describe '#component_id' do
    subject { super().component_id }
    it { is_expected.to eq('1') }
  end
end

shared_examples_for 'command_headers' do
end

shared_examples_for 'event_headers' do
end

shared_examples_for 'key_value_pairs' do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<#{element_name} name='boo' value='bah' />"
    h = described_class.new n.root
    expect(h.name).to eq('boo')
    expect(h.value).to eq('bah')
  end

  it 'has a name attribute' do
    n = described_class.new :boo, 'bah'
    expect(n.name).to eq('boo')
    n.name = :foo
    expect(n.name).to eq('foo')
  end

  it 'has a value param' do
    n = described_class.new :boo, 'en'
    expect(n.value).to eq('en')
    n.value = 'de'
    expect(n.value).to eq('de')
  end

  it 'can determine equality' do
    a = described_class.new :boo, 'bah'
    expect(a).to eq(described_class.new(:boo, 'bah'))
    expect(a).not_to eq(described_class.new(:bah, 'bah'))
    expect(a).not_to eq(described_class.new(:boo, 'boo'))
  end
end
