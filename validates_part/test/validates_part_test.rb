require File.dirname(__FILE__) + '/test_helper'

context "Validates part" do
  
  class Part 
    include Ardes::Validatable
    attr_accessor :foo, :bar
    validates_presence_of :foo, :bar, :message => "is required"
    
    def initialize(foo, bar)
      self.foo = foo
      self.bar = bar
    end
  end
  
  class Whole < ActiveRecord::Base
    acts_as_tableless :foo, :bar
    composed_of :part, :mapping => [[:foo, :foo], [:bar, :bar]]
  end
  
  # validates_part with default configuration
  # errors are added to part, and the error message contains both attrs
  # i.e. "part - foo can't be blank"
  class WholeDefault < Whole
    validates_part :part
  end
  
  # validates_part with merge_errors
  class WholeMergeErrors < Whole
    validates_part :part, :merge_errors => true
  end
        
  specify "should invalidate whole when part is invalid" do
    w = WholeDefault.new
    assert ! w.part.valid?
    assert ! w.valid?
  end
  
  specify "should have errors on whole when merge_errors is true" do
    w = WholeMergeErrors.new
    assert ! w.valid?
    assert_equal(["Bar is required", "Foo is required"], w.errors.full_messages.sort)
  end
  
  specify "should have errors on part attr when merge_errors is false" do
    w = WholeDefault.new
    assert ! w.valid?
    assert_equal(["Part - bar is required", "Part - foo is required"], w.errors.full_messages.sort)
  end
end