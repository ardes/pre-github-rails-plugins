module Ardes#:nodoc:
  # to be extended into ActiveRecord::Base
  #
  # See README for details
  #
  # The solution is a bit complicated, because we can't load the subclass dependencies until after
  # the base class is defined.  (If ruby had a <code>class_defined</code> hook, a companion to <code>inherited</code>, this would be trivial)
  #
  # The solution given here is to load the outstanding dependencies when the subclasses method is called.  This ensures that STI subclasses are
  # loaded just in time to make all the finder magic work.
  #
  # If the Dependency.mechanism is :load (ie. standardly in development mode) then the types are constantized each time ensuring that the
  # right classes are loaded.  If the Dependency.mechanism is :require (i.e. production mode) then the hook in subclasses is removed for subsequent
  # calls.
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
            # Load all dependencies before sublcasses is accessed
            def subclasses_with_has_types
              (type_class_names - [self.name]).each(&:constantize)
              subclasses_without_has_types
            ensure
              # Unless we are in Dependency load mode, we can get rid of 
              # this method hook
              unless Dependencies.mechanism == :load
                class<<self
                  alias_method :subclasses, :subclasses_without_has_types
                  undef_method :subclasses_with_has_types
                  undef_method :subclasses_without_has_types
                end
              end
            end
            alias_method_chain :subclasses, :has_types

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