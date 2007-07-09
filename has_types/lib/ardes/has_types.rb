module Ardes#:nodoc:
  # to be extended into ActiveRecord::Base
  #
  # See README for details
  #
  # The solution is a bit complicated, because we can't load the subclass dependencies until after
  # the base class is defined.  (If ruby had a <code>class_defined</code> hook, a companion to <code>inherited</code>, this would be trivial)
  #
  # The solution given here is to store the outstanding dependencies on the HasTypes module, which are then
  # required when the class descends_from_active_record? method is called (as this is called prior to doing any
  # funny STI stuff).  This method is restored to its original state after the dependencies are loaded.
  #
  # I'm pretty sure this condition serves to load STI subclasses just in time to maek all the finder magic work.
  module HasTypes
    def has_types(*types)
      raise RuntimeError, "can only specify has_types on an STI base class" unless self == self.base_class
      
      unless singleton_methods.include?(:subclass_names)
        self.class_eval do
          cattr_accessor :type_class_names
        
          class<<self
            # intercept calls to descend_from_active_record? and load outstanding dependencies. then wipe
            # all trace of this method intercept
            def descends_from_active_record_with_has_types?
              type_class_names.each {|d| require_dependency(d.underscore) }
              returning descends_from_active_record_without_has_types? do
                class<<self
                  alias_method :descends_from_active_record?, :descends_from_active_record_without_has_types?
                  undef_method :descends_from_active_record_with_has_types?
                  undef_method :descends_from_active_record_without_has_types?
                end
              end
            end
            alias_method_chain :descends_from_active_record?, :has_types
              
            def inherited(child)
              type_class_names.include?(child.name) ? super : raise(NameError, "#{child.name} is not declared in #{child.base_class.name}. Add has_types :#{child.name.underscore} to #{child.base_class.name} class definition")
            end
          end
        end
      end
      
      self.type_class_names = types.collect{|t| t.to_s.classify }
    end
  end
end