require File.dirname(__FILE__) + "/test_helper"

context "Publishing an interface" do  
  test "should be allowed with a class method" do
    Class.new.class_eval do
      include Adhearsion::Publishable
      publish :through => :interface do
        def self.bar
          [1, 2, 3]
        end
      end
    end
    Adhearsion::DrbDoor.instance.interface.bar.should.equal [1, 2, 3]
  end

  test "should be allowed with an alternate interface" do
    Class.new.class_eval do
      include Adhearsion::Publishable
      publish :through => :api do
        def self.bar
          [2, 3, 4]
        end
      end
    end
    Adhearsion::DrbDoor.instance.api.bar.should.equal [2, 3, 4]
  end
  
  test "should be allowed with a metaclass block" do
    Class.new.class_eval do
      include Adhearsion::Publishable
      publish :through => :interface do
        class << self
          def bar
            [3, 2, 1]
          end
        end
      end
    end
    Adhearsion::DrbDoor.instance.interface.bar.should.equal [3, 2, 1]
  end
  
  test "should be allowed from within the metaclass block" do
    # Class.new.class_eval do
    #   include Publishable
    #   class << self
    #     publish :through => :interface do
    #       def baz
    #         [4, 5, 6]
    #       end
    #     end
    #   end
    # end
    # Adhearsion::DrbDoor.instance.interface.baz.should.equal [4, 5, 6]
  end
end

context "Invoking an interface" do
  test "should raise an exception if the method is not found" do
    the_following_code do
      Adhearsion::DrbDoor.instance.interface.foobar.should.equal [1, 2, 3]
    end.should.raise NoMethodError
  end

  test "should raise an exception if the interface is not found" do
    the_following_code do
      Adhearsion::DrbDoor.instance.bad_interface.bar.should.equal [1, 2, 3]
    end.should.raise NoMethodError
  end
end

context "Invoking an interface method via DRb" do
  require 'drb'
  before do
    @door = DRb.start_service "druby://127.0.0.1:9050", Adhearsion::DrbDoor.instance
  end

  test "should return the proper result" do
    client = DRbObject.new nil, DRb.uri
    client.interface.bar.should.equal [3, 2, 1]
  end

  test "should raise an exception for a non-existent interface" do
    client = DRbObject.new nil, DRb.uri
    the_following_code do
      client.interface.bad_interface.should.equal [3, 2, 1]
    end.should.raise NoMethodError
  end

  test "should raise an exception for a non-existent method" do
    client = DRbObject.new nil, DRb.uri
    the_following_code do
      client.interface.interface.foobar.equal [3, 2, 1]
    end.should.raise NoMethodError
  end

  after do
    DRb.stop_service
  end
end
