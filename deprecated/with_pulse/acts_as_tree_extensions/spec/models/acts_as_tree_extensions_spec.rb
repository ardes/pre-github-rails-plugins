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

context "acts_as_tree_extensions (in general)" do
  include ActsAsTreeExtensionsSpecHelper
  fixtures :my_nodes
  
  setup { load_tree }
  
  specify "should preload parent association in children" do
    @a.children.first.parent.should_be @a
  end
  
  specify "should return common_ancestor_of two nodes" do
    @abc.common_ancestor_of(@ad).should == @a
  end
  
  specify "should return nil when getting common_ancestor_of nodes without a common ancestor" do
    @abc.common_ancestor_of(@e).should == nil
    @ad.common_ancestor_of(@a).should == nil
  end
  
  specify "should return leaves of self (descendent nodes with no children) with leaves" do
    @a.leaves.should == [@abc, @ad]
    @e.leaves.should == [@e]
  end
  
  specify "should return child of specified node if node is an ancestor of self with child_of_ancestor(node)" do
    @abc.child_of_ancestor(@a).should == @ab
    @abc.child_of_ancestor(@ab).should == @abc
  end

  specify "should return root node in branch with child_of_ancestor(nil)" do
    @abc.child_of_ancestor(nil).should == @a
  end
  
  specify "should return nil if node is not an ancestor of self with child_of_ancestor" do
    @abc.child_of_ancestor(@e).should == nil
  end
  
  specify "should return ancestors enumerator (ancestors in leaf to root order) with ancestors" do
    ancestors = @abc.ancestors
    ancestors.class.should_be ActiveRecord::Acts::Tree::Extensions::Ancestors
    ancestors.of.should == @abc
    ancestors.include_self.should == false
    ancestors.collect.should == [@ab, @a]
  end
  
  specify "should return ancestors enumerator (self + ancestors in leaf to root order) with self_and_ancestors" do
    ancestors = @abc.self_and_ancestors
    ancestors.class.should_be ActiveRecord::Acts::Tree::Extensions::Ancestors
    ancestors.of.should == @abc
    ancestors.include_self.should == true
    ancestors.collect.should == [@abc, @ab, @a]
  end
  
  specify "should return descendents enumerator (descendents in recursive child descent order) with descendents" do
    descendents = @a.descendents
    descendents.class.should_be ActiveRecord::Acts::Tree::Extensions::Descendents
    descendents.of.should == @a
    descendents.include_self.should == false
    descendents.collect.should == [@ab, @abc, @ad]
  end
  
  specify "should return descendents enumerator (self + descendents in recursive child descent order) with self_and_descendents" do
    descendents = @a.self_and_descendents
    descendents.class.should_be ActiveRecord::Acts::Tree::Extensions::Descendents
    descendents.of.should == @a
    descendents.include_self.should == true
    descendents.collect.should == [@a, @ab, @abc, @ad]
  end
end

context "acts_as_tree_extensions predicate methods (? methods)" do
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
end

context "acts_as_tree enumerator" do
  include ActsAsTreeExtensionsSpecHelper
  fixtures :my_nodes
  
  setup { load_tree }
  
end

context "acts_as_tree_extension class" do
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
    leaves[1].parent.should_be roots[0]
    roots[1].should_be leaves[2]
  end
end