module ActiveRecord
  module Associations
    module Extensions
      def self.included(base)
        base.class_eval do
          extend ClassMethods
          class_inheritable_reader :when_nil_procs
          write_inheritable_attribute(:when_nil_procs, {})
        end
      end
      
      module ClassMethods
        def when_nil(association, &block)
          self.when_nil_procs[association.to_sym] = block
          class_eval <<-end_eval
            def #{association}_with_when_nil(*args)
              self.when_nil_procs[:#{association}].call(self) if #{association}_without_when_nil.nil?
              return #{association}_without_when_nil(*args)
            end
            alias_method_chain :#{association}, :when_nil
          end_eval
        end
      end
    end
  end
end