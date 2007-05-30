module SslRequirementIf
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def ssl_requirement_if(&block)
      self.class_eval do
        include SslRequirement
        define_method(:ensure_proper_protocol_with_condition) do 
          block.call(self) ? ensure_proper_protocol_without_condition : true
        end
        alias_method_chain :ensure_proper_protocol, :condition
      end
    end
  end
end
