module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Tree #:nodoc:
      # adds extra functionality (all backward compatible) to acts_as_tree
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
        def acts_as_tree_with_extensions(*args)
          self.class_eval do
            acts_as_tree_without_extensions(*args)
            include InstanceMethods
            extend ClassMethods
          end
        end
        
        class AncestorEnumerator
          include Enumerable
          
          def initialize(node, options = {})
            @node = options[:include_self] ? node : node.parent
          end
          
          def each
            node = @node
            while node
              yield(node)
              node = node.parent
            end
          end
        end
        
        class DescendentEnumerator
          include Enumerable
          
          def initialize(node, options = {})
            @nodes = options[:include_self] ? [node] : node.children
          end
          
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
          
          def ancestor_enumerator(options = {})
            AncestorEnumerator.new(self, options)
          end
          
          def descendent_enumerator(options = {})
            DescendentEnumerator.new(self, options)
          end
          
          # Return the ancestors of the current node.  The ancestors are in leaf to
          # root order.
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
            
            options[:to_child_of] = options[:to].parent if options[:to]
            nodes = []
            if options[:to_child_of]
              stop_at = options[:to_child_of]
            elsif options[:to]
              stop_at = options[:to].parent
            else
              stop_at = false
            end
            ancestor_enumerator(:include_self => options[:include_self]).each do |node|
              return nodes if node == stop_at
              nodes << node
            end
            stop_at == false ? nodes : nil
          end
          
          # is an ancestor of the specified node
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include self in the ancestor check
          def ancestor_of?(node, options = {})
            node.ancestor_enumerator(options).include? self
          end
          
          # is a descendent of the specified node
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include self in the descendent check
          def descendent_of?(node, options = {})
            self.ancestor_enumerator(options).include? node
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

        protected
          def ancestors_to_child_of(to_child_of, options)
            nodes = []
            ancestor_enumerator(options) do |node|
              return nodes if to_child_of == node
              nodes << node
            end
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
          
          # Returns the common ancestor of the passed nodes, or nil if
          # there is no common ancestor.
          #
          # Optionally takes the following argument:
          # * <tt>:include_self</tt>: (boolean) include the nodes as ancestor candidates
          def common_ancestor_of(n1, n2, options = {})
            n1.ancestor_enumerator(options).each {|i| n2.ancestor_enumerator(options).each {|j| return i if i == j }}
            nil
          end
        end
      end
    end
  end
end