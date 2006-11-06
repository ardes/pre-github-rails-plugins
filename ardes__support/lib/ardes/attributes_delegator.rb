module Ardes
  module AttributesDelegator
    def self.included(base)
      base.send :extend, ClassMethods
    end
    
    module ClassMethods
      def delegates_attributes_to(method)
        self.class_eval do
          class_inheritable_reader :attributes_delegate_method
          write_inheritable_attribute(:attributes_delegate_method, method)
          include DelegationMethods
        end
      end
      
      module DelegationMethods
        def self.included(base)
          base.class_eval do
            alias_method_chain :respond_to?, :attributes_delegator
            alias_method_chain :method_missing, :attributes_delegator
          end
        end
        
        def respond_to_with_attributes_delegator?(method_signature)
          delegate = (send(self.attributes_delegate_method) rescue nil)
          respond_to_without_attributes_delegator?(method_signature) || (delegate.respond_to?(:attribute_names) && delegate.attribute_names.include?(method_signature.to_s.sub(/\?|\=/,'')))
        end

        def method_missing_with_attributes_delegator(method_signature, *args)
          delegate = (send(self.attributes_delegate_method) rescue nil)
          if delegate.respond_to?(:attribute_names) && delegate.attribute_names.include?(method_signature.to_s.sub(/\?|\=/,''))
            delegate.send(method_signature, *args)
          else
            method_missing_without_attributes_delegator(method_signature, *args)
          end
        end
      end
    end
  end
end