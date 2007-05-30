require File.dirname(__FILE__) + '/test_helper.rb'
require 'ardes/attributes_delegator'

context "Ardes Attributes Delegator" do
  
  class AttrDelegate
    include Ardes::Attributes
    
    attribute :foo
    
    def bar; :bar; end
  end
  
  class AttrDelegator
    include Ardes::AttributesDelegator
    attr_accessor :delegate
    delegates_attributes_to :delegate
  end

  def setup
    @test = AttrDelegator.new
    @test.delegate = AttrDelegate.new
  end
  
  specify "should repsond to delegate attribute methods" do
    assert @test.respond_to?("foo")
    assert @test.respond_to?("foo=")
    assert @test.respond_to?("foo?")
  end
  
  specify "should no respond to non delegate attribute methods" do
    assert !@test.respond_to?("bar")
    assert !@test.respond_to?("baz")
  end
  
  specify "should pass attribute methods to delegate" do
    @test.foo = 'chicken'
    assert @test.foo?
    assert @test.delegate.foo?
    assert_equal 'chicken', @test.foo
    assert_equal 'chicken', @test.delegate.foo
  end
    
  specify "should not respond to methods when delegate goes away" do
    @test.delegate = nil
    assert ! @test.respond_to?("foo")
  end
end
    