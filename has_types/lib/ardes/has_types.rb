module Ardes#:nodoc:
  # to be extended into ActiveRecord::Base
  #
  # See README for details
  #
  # The solution is a bit complicated, because we can't load the subclass dependencies until after
  # the base class is defined.  (If ruby had a <code>class_defined</code> hook, a companion to <code>inherited</code>, this would be trivial)
  #
  # The solution given here is to load the outstanding dependencies when the load_type_dependencies is called.
  #
  # This mixin makes sure to call that method before
  #   - descends_from_active_record?
  #   - type_condition
  #
  # This ensures that STI subclasses are loaded just in time to make all the finder magic work.
  #
  # You can call this method when you need to be sure that all of the subclasses are loaded.
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
      
      unless respond_to?(:load_type_dependencies)
        self.class_eval do
          cattr_accessor :type_class_names
          extend TypeFactory if options[:type_factory]
          
          class<<self
            # this only needs to be called once, so blow myself away afterwards
            def load_type_dependencies
              (type_class_names - [self.name]).each(&:constantize)
              class<<self
                def load_type_dependencies; end
              end
            end
            
            def descends_from_active_record_with_has_types?
              load_type_dependencies
              descends_from_active_record_without_has_types?
            end
            alias_method_chain :descends_from_active_record?, :has_types
            
            def type_condition_with_has_types
              load_type_dependencies
              type_condition_without_has_types
            end
            alias_method_chain :type_condition, :has_types
            
            def inherited(child)
              type_class_names.include?(child.name) ? super : raise(NameError, "#{child.name} is not declared in #{child.base_class.name}. Add has_types :#{child.name.underscore} to #{child.base_class.name} class definition")
            end
          end
        end
        
        self.type_class_names = types.collect(&:to_s).collect(&:classify)
      end
    end
    
    # extended into model when :type_factory => true
    module TypeFactory
      def new(attributes = nil, &block)
        descends_from_active_record? # to load dependencies
        if attributes && attributes.stringify_keys! && attributes["type"] 
          type = attributes.delete("type").to_s.classify
          allowed_types = [self.name] + send(:subclasses).collect(&:name)
          allowed_types.include?(type) or raise ArgumentError, "type: #{type} must be one of #{allowed_types.to_sentence(:connector => 'or')}"
          # Scope subclass to same create attributes as this class.
          klass = type.constantize
          klass.send(:with_scope, :create => (scope(:create) || {})) do
            return klass.new(attributes, &block)
          end
        else
          super(attributes, &block)
        end
      end
    end
  end
end