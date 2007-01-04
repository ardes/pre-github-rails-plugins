module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Tree #:nodoc:
      # adds extra functionality (all backward compatible) to acts_as_tree
      #
      # Summary:
      # * children association is preloaded with parent, to minimize database access when traversing the tree
      # * various predicate methods for telling what type a node is?
      # * enumerator objects for ancestors and descendents
      # * methods to find leaves, and common nodes of different branches
      #
      # Usage is the same as for <tt>acts_as_tree</tt>
      #
      # If you want to use acts_as_tree without the extensions for some of your classes, 
      # then do <tt>acts_as_tree_without_extensions</tt>.
      module Extensions
        def self.extended(base)
          class<<base
            alias_method_chain :acts_as_tree, :extensions
          end
        end
          
        # Specifies that the ActiveRecord acts_as_tree, with some extra functionality
        def acts_as_tree_with_extensions(options = {})
          self.class_eval do
            acts_as_tree_without_extensions(options)
            include InstanceMethods
            extend ClassMethods
          end
        end

        # Enumerable object representing a node's ancestors.
        #
        # One use for this, over an array, is doing tree operations on large trees - you might
        # want to visit only a subset of the tree.
        class AncestorEnumerator
          include Enumerable
          
          # Create a new AncestorEnumerator with a node
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include the node itself as an ancestor
          def initialize(node, options = {})
            @node = options[:include_self] ? node : node.parent
          end
          
          # Visit each of the ancestors in leaf to root order
          def each
            node = @node
            while node
              yield(node)
              node = node.parent
            end
          end
        end
        
        # Enumerable object representing a node's descendents
        class DescendentEnumerator
          include Enumerable
          
          # Create a new DescendentEnumerator with a node
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include the node itself as a descendent
          def initialize(node, options = {})
            @nodes = options[:include_self] ? [node] : node.children
          end
          
          # Visit each of the descendents recursively in order of each node's child.
          # 
          # For example, a descendent enumerator on node (a) in the following tree:
          #   a
          #   +-ab
          #   | +-abc
          #   | +-abd
          #   +-ae
          #     +-aef
          #
          # Would yield nodes in the following order:
          #   ab, abc, abd, ae, aef
          def each
            visit = proc do |node|
              yield(node)
              node.children.each do |child|
                visit.call(child)
              end
            end
            @nodes.each {|n| visit.call(n)}
          end
        end
        
        module InstanceMethods
          def self.included(base)
            base.class_eval do
              alias_method_chain :children, :parent
            end
          end
          
          # children association is preloaded with parent association target == self
          def children_with_parent(*args)
            children = children_without_parent(*args)
            children.each do |child|
              parent = ActiveRecord::Associations::HasOneAssociation.new(child, self.class.reflect_on_association(:parent))
              parent.target = self
              child.instance_variable_set("@parent", parent)
            end
            children
          end
          
          # return an AncestorEnumerator for self
          def ancestor_enumerator(options = {})
            AncestorEnumerator.new(self, options)
          end
          
          # is an ancestor of the specified node
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include self in the ancestor check
          def ancestor_of?(node, options = {})
            node.ancestor_enumerator(options).include? self
          end
          
          # Return the ancestors of the current node in an Array in the order
          # defined by AncestorEnumerator
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include self in the returned array.
          #
          # Also optionaly takes one of the following arguments:
          # * <tt>:to</tt>: (a node) stop at the specified node
          # * <tt>:to_child_of</tt>: (a node) stop at the child of specified node
          #
          # If the node specified by either of the above options is not present in the
          # ancestors of the current node, then return nil
          def ancestors(options = {})
            return ancestors_to_child_of(options[:to_child_of], :include_self => options[:include_self]) if options[:to_child_of]
            return ancestors_to(options[:to], :include_self => options[:include_self]) if options[:to]
            ancestor_enumerator(:include_self => options[:include_self]).to_a
          end
          
          # return an DescendentEnumeratorEnumerator for self
          def descendent_enumerator(options = {})
            DescendentEnumerator.new(self, options)
          end
         
          # is a descendent of the specified node
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include self in the descendent check
          def descendent_of?(node, options = {})
            self.ancestor_enumerator(options).include? node
          end
          
          # Return the descendents of the current node in an Array in the order
          # defined by DescendentEnumerator
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include self in the returned array.
          #
          def descendents(options = {})
            descendent_enumerator(options).to_a
          end
          
          # is a leaf node (has no children)
          def leaf?
            children.length == 0
          end
          
          # is a root node (has no parent)
          def root?
            parent_id.nil?
          end
          
          # is a branch node (has more than one child)
          def branch?
            children.length > 1
          end
          
          # is a child node (has a parent)
          def child?
            !parent_id.nil?
          end
          
          # Return this node's leaves.
          # This method loads all children from the db, useful for getting a part of the tree for programatic manipulation.
          def leaves
            descendent_enumerator(:include_self => true).select {|n| n.leaf? }
          end
          
          # Returns the ancestor in common with passed nodes, or nil if
          # there is no common ancestor.
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include the self, and passed node, as ancestor candidates
          def common_ancestor_of(node, options = {})
            self.ancestor_enumerator(options).each {|i| node.ancestor_enumerator(options).each {|j| return i if i == j }}
            nil
          end

        protected
          # return the ancestors up to the child of specified node
          def ancestors_to_child_of(node, options = {})
            ancestors = []
            ancestor_enumerator(options).each {|n| return ancestors if n == node; ancestors << n}
            nil
          end
          
          # return the ancestors up to the specified node
          def ancestors_to(node, options = {})
            ancestors = []
            ancestor_enumerator(options).each {|n| ancestors << n; return ancestors if n == node}
            nil
          end
        end
        
        module ClassMethods
          # Load the entire tree and returns its roots and leaves in two arrays.
          # This is useful for keeping a reference to every node, which can then be 
          # searched/manipulated programatically.
          def roots_and_leaves
            roots = self.roots
            leaves = roots.inject([]) {|l, n| l += n.leaves}
            [roots, leaves]
          end
          
          # return the tree's leaves
          def leaves
            roots_and_leaves.last
          end
        end
      end
    end
  end
end