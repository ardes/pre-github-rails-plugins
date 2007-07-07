module Ardes#:nodoc:
  # to be extended into ActiveRecord::Base
  module HasTypes
    def self.extended(base)
      base.class_eval do
        class<<self
          def inherited_with_has_types(child)
            Ardes::HasTypes.require_dependencies
            inherited_without_has_types(child)
          end
          alias_method_chain :inherited, :has_types
        end
      end
    end
    
    def self.add_dependency(*dependencies)
      @dependencies_for_next_inherit ||= []
      @dependencies_for_next_inherit += dependencies
    end
    
    def self.require_dependencies
      if @require_dependencies
        deps, @require_dependencies = @require_dependencies, nil
        deps.each {|d| require_dependency(d.underscore)}
      end
      if @dependencies_for_next_inherit
        @require_dependencies, @dependencies_for_next_inherit = @dependencies_for_next_inherit, nil
      end
    end
    
    def has_types(*types)
      raise "can only specify has_types on an STI base class" unless self == self.base_class
      
      unless singleton_methods.include?(:subclass_names)
        self.class_eval do
          cattr_accessor :type_class_names
        
          class<<self
            def inherited(child)
              type_class_names.include?(child.name) ? super : raise("#{child.name} is not declared in #{child.base_class.name}. Add has_types :#{klass.underscore} to #{child.base_class.name} class definition")
            end
          end
        end
      end
      
      self.type_class_names = types.collect{|t| t.to_s.classify }
      Ardes::HasTypes.add_dependency(*self.type_class_names)
    end
  end
end