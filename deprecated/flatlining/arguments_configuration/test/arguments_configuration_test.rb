require File.dirname(__FILE__) + '/test_helper'

context "Arguments configuration" do
  
  specify "should repsond to configuration, without_configuration, apply_defaults and shebang" do
    Array.new.respond_to? :without_configuration
    Array.new.respond_to? :configuration
    Array.new.respond_to? :apply_defaults
    Array.new.respond_to? :apply_defaults!
  end
  
  specify "should create last hash object when getting configuration if none present" do
    a = []
    a.configuration[:foo] = :bar
    assert_equal([{:foo => :bar}], a)
  end
  
  specify "should return last Hash when getting configuration" do
    assert_equal({:foo => 1}, [1,2,3,{:foo => 1}].configuration)
    assert_equal({:foo => 1}, [{:foo => 1}].configuration)
    assert_equal({},          [].configuration)
    assert_equal({},          [1,2,3].configuration)
  end
  
  specify "should be without last Hash when getting without_configuration" do
    assert_equal([],      [].without_configuration)
    assert_equal([],      [{:foo => 1}].without_configuration)
    assert_equal([1,2,3], [1,2,3].without_configuration)
    assert_equal([1,2,3], [1,2,3,{:foo => 1}].without_configuration)
  end
  
  specify "should replace array elements only if none present when apply_defaults" do
    assert_equal([1,2,3],                [].apply_defaults(1,2,3))
    assert_equal([1,2,3,{:foo => :bar}], [{:foo => :bar}].apply_defaults(1,2,3))
  end
  
  specify "should replace array elements according to position in array when using apply_defaults" do
    assert_equal(['a', 2, 3],           ['a'].apply_defaults(1, 2, 3))
    assert_equal(['a', 'b', 3],         ['a', 'b'].apply_defaults(1, 2, 3))
    assert_equal(['a', 'b', 'c'],       ['a', 'b', 'c'].apply_defaults(1, 2, 3))
    assert_equal(['a', 'b', 'c', 'd'],  ['a', 'b', 'c', 'd'].apply_defaults(1, 2, 3, 4))
  end
  
  specify "should not overwrite values when already present when apply_defaults" do
    assert_equal([1,{:foo => true}], [1,{:foo => true}].apply_defaults(:foo => false))
  end
  
  specify "should append non existing options when apply_defaults" do
    assert_equal([1,{:foo => true}],               [1].apply_defaults(:foo => true))
    assert_equal([1,{:foo => true, :bar => true}], [1,{:foo => true}].apply_defaults(:bar => true))
  end
  
  specify "should modify original array when apply_defaults shebang" do
    a = [{:foo => true}]
    a.apply_defaults!(1, 2, :foo => false, :bar => true)
    assert_equal [1, 2, {:foo => true, :bar => true}], a
  end
end