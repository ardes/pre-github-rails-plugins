module ActiveRecord#:nodoc:
  module Associations#:nodoc:
    #
    # Some extra functionality to do with associations
    #
    module Extensions
      # Use this to specify what should be done when a nil association is accessed
      # This is useful for a model where you _always_ have an associated object
      #
      # For example:
      #  class Signup < ActiveRecord::Base
      #    has_one :user
      #    
      #    when_nil :user do |record|
      #      record.build_user
      #    end
      #  end
      #
      # When the (nil) user association is accessed, the above block is executed,
      # and then the association is accessed again.
      #  
      #  s = Signup.new
      #  s.user # user is nil, so execute the block, and then call user again which returns
      #         # => #<User:0x347bb0 ...
      # s.user # user is not nil, so just return
      #         # => #<User:0x347bb0 ...
      def when_nil(association, &block)
        procs = (read_inheritable_attribute(:when_nil) or write_inheritable_attribute(:when_nil, {}))
        procs[association.to_sym] = block
        class_eval <<-end_eval
          def #{association}_with_when_nil(*args)
            if (result = #{association}_without_when_nil(*args)) != nil
              result
            else
              self.class.read_inheritable_attribute(:when_nil)[:#{association}].call(self)
              #{association}_without_when_nil(*args)
            end
          end
          alias_method_chain :#{association}, :when_nil
        end_eval
      end
      
      # Use this to preload self as the belongs_to association when a has_one, or has_many association
      # is created.  This means that 'child' ActiveRecords that reference the 'parent' (with a :belongs_to, or :has_one)
      # will, when accessed via the 'parent', be created with a reference to the parent.
      #
      # Usage:
      #   preload_self_in :assoc [, :assoc2].. [, :as => :assoc_name]
      #
      # Example
      #  class Handbag
      #    has_many :things
      #    has_one :strap
      #    preload_self_in :things
      #    preload_self_in :strap, :as => :bag
      #  end
      #
      #  class Thing
      #    belongs_to :handbag
      #  end
      #
      #  class Strap
      #    belongs_to :bag
      #  end
      #
      #  t = Handbag.find(1).things.first
      #
      #  t.handbag # <= this is preloaded, so no extra database query will be issued
      #
      # If the target associated class does not specify :belongs_to, or :has_one, then this method has no effect
      #
      # Note: Make sure that 
      def preload_self_in(*preload_in)
        options = preload_in.last.is_a?(Hash) ? preload_in.pop : {}
        parent_name = (options[:as] || self.name.underscore).to_sym
        preload_in.each do |child_name|
          child_name = child_name.to_sym
          child_assoc = reflect_on_association(child_name)
          parent_assoc = child_assoc.klass.reflect_on_association(parent_name)
          
          if parent_assoc && [:belongs_to, :has_one].include?(parent_assoc.macro)
            parent_assoc_class = "::ActiveRecord::Associations::#{parent_assoc.macro.to_s.classify}Association"
            
            class_eval <<-end_eval
              def #{child_name}_with_preload(*args)
                if assoc = #{child_name}_without_preload(*args)
                  children = assoc.is_a?(Array) ? assoc : [assoc]
                  parent_assoc = children.first.class.reflect_on_association(:#{parent_name})
                  children.each do |child|
                    parent = #{parent_assoc_class}.new(child, parent_assoc)
                    parent.target = self
                    child.instance_variable_set("@#{parent_name}", parent)
                  end
                end
                assoc
              end
              alias_method_chain :#{child_name}, :preload
            end_eval
          end
        end
      end
    end
  end
end