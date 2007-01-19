require File.join(File.dirname(__FILE__), '../spec_helper')
require File.join(File.dirname(__FILE__), '../fixtures/my_node')
ActiveRecord::Migration.suppress_messages { require File.join(File.dirname(__FILE__), '../fixtures/my_nodes_schema') }

module ActsAsTreeExtensionsSpecHelper
  # fixtures define a tree setup like this:
  #   +-a
  #   | +-ab
  #   | | +-abc
  #   | +-ad
  #   +-e
  # nodes are named so that you can read the tree structure from them in the tests
  def load_tree
    @a = my_nodes :a
    @ab = my_nodes :ab
    @abc = my_nodes :abc
    @ad = my_nodes :ad
    @e = my_nodes :e
  end
end

context "An ActiveRecord with acts_as_tree extensions (in general)" do
  include ActsAsTreeExtensionsSpecHelper
  fixtures :my_nodes
  
  setup { load_tree }
  
  specify "should be root? when node has no parent" do
    @a.should_be_root
    @ab.should_not_be_root
    @abc.should_not_be_root
    @ad.should_not_be_root
    @e.should_be_root
  end
  
  specify "should be branch? when node has more than one child" do
    @a.should_be_branch
    @ab.should_not_be_branch
    @abc.should_not_be_branch
    @ad.should_not_be_branch
    @e.should_not_be_branch
  end
  
  specify "should be child? when node has a parent" do
    @a.should_not_be_child
    @ab.should_be_child
    @abc.should_be_child
    @ad.should_be_child
    @e.should_not_be_child
  end
  
  specify "should be leaf? when node has no children" do
    @a.should_not_be_leaf
    @ab.should_not_be_leaf
    @abc.should_be_leaf
    @ad.should_be_leaf
    @e.should_be_leaf
  end
  
  specify "should be ancestor_of? when argument is ancestor of self" do
    @a.should_be_ancestor_of(@ab)
    @a.should_be_ancestor_of(@abc)
    @ab.should_be_ancestor_of(@abc)
    @a.should_not_be_ancestor_of(@a)
    @e.should_not_be_ancestor_of(@ab)
  end
  
  specify "should be descendent_of? when argument is descendent of self" do
    @ab.should_be_descendent_of(@a)
    @abc.should_be_descendent_of(@a)
    @abc.should_be_descendent_of(@ab)
    @a.should_not_be_descendent_of(@a)
    @ab.should_not_be_descendent_of(@e)
  end
  
  specify "should allow self to be ancestor_of? self when called with :include_self => true" do
    @a.should_be_ancestor_of(@a, :include_self => true)
  end

  specify "should allow self to be descendent_of? self when called with :include_self => true" do
    @a.should_be_descendent_of(@a, :include_self => true)
  end
  
  specify "should return leaves of self (descendent nodes with no children)" do
    @a.leaves.should == [@abc, @ad]
    @e.leaves.should == [@e]
  end
  
  specify "should return ancestors of self in leaf to root order" do
    @abc.ancestors.should == [@ab, @a]
    @ad.ancestors.should == [@a]
  end
  
  specify "should return empty array if there are no ancestors" do
    @a.ancestors.should == []
  end
  
  specify "should include self in ancestors when called with :include_self => true" do
    @abc.ancestors(:include_self => true).should == [@abc, @ab, @a]
  end
  
  specify "should stop at specified node when getting ancestors with :to => node" do
    @abc.ancestors(:to => @ab).should == [@ab]
  end
 
  specify "should stop at child of specified node when getting ancestors with :to_child_of => node" do
    @abc.ancestors(:to_child_of => @a).should == [@ab]
  end
  
 specify "should return nil when getting ancestors with :to(_child_of) => node, where node is not an ancestor of self" do
   @abc.ancestors(:to => @e).should == nil
   @abc.ancestors(:to_child_of => @e).should == nil
 end

  specify "should return iterator on ancestors with ancestor_enumerator" do
    @abc.ancestor_enumerator.collect{|n| n}.should == [@ab, @a]
  end
  
  specify "should return iterator on self and ancestors with ancestor_enumerator :include_self => true" do
    @abc.ancestor_enumerator(:include_self => true).collect{|n| n}.should == [@abc, @ab, @a]
  end
  
  specify "should return iterator on descendents with ancestor_enumerator" do
    @a.descendent_enumerator.collect{|n| n}.should == [@ab, @abc, @ad]
  end
  
  specify "should return iterator on self and descendents with ancestor_enumerator :include_self => true" do
    @a.descendent_enumerator(:include_self => true).collect{|n| n}.should == [@a, @ab, @abc, @ad]
  end
  
  specify "should preload parent association in children" do
    @a.children.first.parent.should_be @a
  end
end

context "An ActiveRecord class with acts_as_tree extensions" do
  include ActsAsTreeExtensionsSpecHelper
  fixtures :my_nodes
  
  setup { load_tree }
  
  specify "should return leaves" do
    MyNode.leaves.should == [@abc, @ad, @e]
  end

  specify "should return roots_and_leaves" do
    MyNode.roots_and_leaves.should == [[@a, @e], [@abc, @ad, @e]]
  end

  specify "should return roots_and_leaves associated with each other" do
    roots, leaves = MyNode.roots_and_leaves
    roots[0].children[1].should_be leaves[1]
    roots[1].should_be leaves[2]
  end
  
  specify "should return common_ancestor_of two nodes" do
    MyNode.common_ancestor_of(@abc, @ad).should == @a
  end
  
  specify "should return nil when getting common_ancestor_of nodes without a common ancestor" do
    MyNode.common_ancestor_of(@abc, @e).should == nil
    MyNode.common_ancestor_of(@ad, @a).should == nil
  end
  
  specify "should include nodes when getting common_ancestor_of with :include_self => true" do
    MyNode.common_ancestor_of(@ad, @a, :include_self => true).should == @a
  end
end