# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Rayo
    class Client
      describe ComponentRegistry do
        let(:uri)       { 'abc123' }
        let(:component) { double 'Component', source_uri: uri }

        it 'should store components and allow lookup by ID' do
          subject << component
          expect(subject.find_by_uri(uri)).to be component
        end

        it 'should allow deletion of components' do
          subject << component
          expect(subject.find_by_uri(uri)).to be component
          subject.delete component
          expect(subject.find_by_uri(uri)).to be_nil
        end
      end
    end
  end
end
