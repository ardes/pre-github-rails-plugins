require File.dirname(__FILE__) + '/test_helper.rb'
require 'ardes/attributes'

context "Ardes Attributes" do
  
  class MyClass
    include Ardes::Attributes
    
    attribute :foo, "bar", :bar
  end
  
  def setup
    @test = MyClass.new
  end
  
  specify "should remove duplicate attribute_names nad convert to strings" do
    assert_equal ["foo", "bar"], MyClass.attribute_names
  end
  
  specify "should respond to attribute accessor methods" do
    ["foo", "foo=", "foo?", "bar", "bar?", "bar="].each do |method|
      assert @test.respond_to?(method), "Should repsond to '#{method}'"
    end
  end
  
  specify "should return duplicates in attributes hash" do
    @test.foo = [1,2,3]
    attrs = @test.attributes
    attrs["foo"] << 4 
    assert_equal [1,2,3], @test.foo
  end
  
  specify "should set attribute via equal and index methods" do
    @test.foo = 1
    assert @test.foo, 1
    @test[:foo] = 2
    assert @test.foo, 2
    @test["foo"] = 3
    assert @test.foo, 3
  end
  
  specify "should have all attributes even when not set" do
    assert_equal({"foo" => nil, "bar" => nil}, @test.attributes)
  end
  
  specify "should assign dups to attributes" do
    attrs = {:foo => 1, :bar => 2}
    @test.attributes = attrs
    attrs[:foo] = 3
    assert_equal({"foo" => 1, "bar" => 2}, @test.attributes)
  end
end
    