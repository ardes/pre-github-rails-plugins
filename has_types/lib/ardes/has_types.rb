module Ardes#:nodoc:
  # to be extended into ActiveRecord::Base
  #
  # See README for details
  #
  # The solution is a bit complicated, because we can't load the subclass dependencies until after
  # the base class is defined.  (If ruby had a <code>class_defined</code> hook, a companion to <code>inherited</code>, this would be trivial)
  #
  # The solution given here is to load the outstanding dependencies when the classes descends_from_active_record? method is called.
  # This is called before any queries that need type conditions.  The dependency laoding happens only once, as the the method is
  # returned to its original state afterwards.
  #
  # I'm pretty sure this condition serves to load STI subclasses just in time to make all the finder magic work.
  #
  # === Options
  #
  # :type_factory (default false)
  #
  # When this is set to true, new() is extended so that it will return an object specified by :type attribute.
  module HasTypes
    def has_types(*types)
      raise RuntimeError, "can only specify has_types on an STI base class" unless self == self.base_class
      
      options = types.last.is_a?(Hash) ? types.pop : {}
      
      self.class_eval do
        cattr_accessor :type_class_names
      
        extend TypeFactory if options[:type_factory]
        
        class<<self
          # Intercept calls to descend_from_active_record? and load outstanding dependencies, then wipe
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
      
      self.type_class_names = types.collect{|t| t.to_s.classify }
    end
    
    # extended into model when :type_factory => true
    module TypeFactory
      def new(attributes = nil)
        descends_from_active_record? # to load dependencies
        if attributes && attributes[:type] && attributes[:type].to_s != self.name
          type = attributes.delete(:type).to_s.classify
          subclass_names = send(:subclasses).collect(&:name)
          raise ArgumentError, "type: #{type} must be one of #{subclass_names.to_sentence(:connector => 'or')}" unless subclass_names.include?(type)
          type.constantize.new(attributes)
        else
         super(attributes)
        end
      end
    end
  end
end