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

        # Base class for acts_as_tree enumerators
        #
        # For BC reasons we implement an Array proxy
        class Enumerator
          include Enumerable
          attr_reader :of, :include_self

          def initialize(node, options = {})
            @of = node
            @include_self = !!options[:include_self]
          end
          
          def method_missing(method, *args, &block)
            proxy_array.send(method, *args, &block)
          end
          
          def respond_to?(method)
            super(method) || proxy_array.respond_to?(method)
          end
          
          def inspect
            "<#{of.inspect}#{include_self ? ' and its' : "'s"} #{self.class.name.demodulize.downcase}>"
          end
          
          def ==(other)
            self.proxy_array == other.proxy_array
          end
          
          def ===(other)
            self.proxy_array === other || self == other
          end
          
          # Returns the elements to (i) the argument, or (ii) the point where the block first evaluates to true.
          # If the argument is never found, or the block never evaluates to true, nil is returned.
          #
          # Call this with either an argument or a block, but not both
          def to(stop_at = nil, &block)
            block = proc {|n| n == stop_at} if stop_at
            array = []
            each do |element|
              array << element
              return array if block.call(element)
            end
            nil
          end 

        protected
          def proxy_array
            @array ||= self.to_a
          end
        end
        
        class Ancestors < Enumerator
          # Visit each of the ancestors in leaf to root order
          def each
            node = include_self ? of : of.parent
            while node
              yield(node)
              node = node.parent
            end
          end
          
          # stop at child of specified node
          def to_child_of(node)
            to {|n| n.parent == node}
          end
        end
        
        class Descendents < Enumerator
          # visit each of the descendents in recursive child descent order
          def each(&block)
            yield(of) if include_self
            of.children.each {|n| yield_on_self_and_children(n, &block) }
          end
          
        protected
          def yield_on_self_and_children(node, &block)
            yield(node)
            node.children.each {|child| yield_on_self_and_children(child, &block)}
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
          
          def ancestors
            Ancestors.new self
          end
          
          def self_and_ancestors
            Ancestors.new self, :include_self => true
          end
          
          def descendents
            Descendents.new self
          end
          
          def self_and_descendents
            Descendents.new self, :include_self => true
          end
          
          # is an ancestor of the specified node
          def ancestor_of?(node)
            node.ancestors.include? self
          end
         
          # is a descendent of the specified node
          def descendent_of?(node)
            self.ancestors.include? node
          end
          
          # is a leaf node (has no children)
          def leaf?
            children.length == 0
          end
          
          # is a root node (has no parent)
          def root?
            parent.nil?
          end
          
          # is a child node (has a parent)
          def child?
            !parent.nil?
          end
          
          # Return this node's leaves.
          # This method loads all children from the db, useful for getting a part of the tree for programatic manipulation.
          def leaves
            self_and_descendents.select &:leaf?
          end
          
          # Returns the ancestor in common with passed nodes, or nil if
          # there is no common ancestor.
          def common_ancestor_of(node)
            ancestors.each {|i| node.ancestors.each {|j| return i if i == j }}
            nil
          end

          # Returns the child (or nil if there is none) of the passed node that is an ancestor of
          # this node.  If passed nil, the root of self is returned
          def child_of_ancestor(node)
            self_and_ancestors.detect {|n| n.parent == node}
          end
        end
        
        module ClassMethods
          # Load the entire tree and returns its roots and leaves in two arrays.
          # This is useful for keeping a reference to every node, which can then be 
          # searched/manipulated programatically.
          def roots_and_leaves
            roots = self.roots
            [roots, roots.collect(&:leaves).flatten]
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