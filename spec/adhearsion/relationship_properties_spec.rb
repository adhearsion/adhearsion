require 'spec_helper'
require 'adhearsion/foundation/relationship_properties'

describe "Module#relationships" do

  describe "Overriding relationships in subclasses" do

    it "should be overridable in subclasses" do
      super_class = Class.new do
        relationships :storage_medium => Array
      end
      sub_class = Class.new(super_class) do
        relationships :storage_medium => Hash
      end
      super_class.new.send(:storage_medium).should be Array
      sub_class.new.send(:storage_medium).should be Hash
    end

    it "should not affect other defined relationships" do
      super_class = Class.new do
        relationships :io_class => TCPSocket, :error_class => StandardError
      end
      sub_class = Class.new(super_class) do
        relationships :error_class => RuntimeError
      end
      super_class.new.send(:io_class).should be TCPSocket
      sub_class.new.send(:io_class).should be TCPSocket
    end

  end

  it "should be accessible within instance methods of that Class as another instance method" do
    klass = Class.new do
      relationships :struct => Struct
      def new_struct
        struct.new
      end
    end
  end

  it "should be accessible in subclasses" do
    super_class = Class.new do
      relationships :number_class => Bignum
    end

    Class.new(super_class) do
      def number_class_name
        number_class.name
      end
    end.new.number_class_name.should == "Bignum"

  end

end