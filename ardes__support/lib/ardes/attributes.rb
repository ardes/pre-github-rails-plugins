module Ardes
  # includes support for an attributes instance variable, with default readers and writers
  #
  # When writing custom accessors, use read_attribute, and write_attribute to access/affect the attributes hash
  #
  # This is useful for mimicing the attribute behaviour of ActiveRecord objects
  # 
  # Example
  #
  #   class Foo
  #     include Ardes::Attributes
  #     attributes :foo, :bar
  #   end
  #
  #   f = Foo.new
  #   f.attribute_names # => [:foo, :bar]
  #     
  module Attributes
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        class_inheritable_reader :attribute_names
        write_inheritable_attribute(:attribute_names, [])
        alias_method_chain :method_missing, :attributes
        alias_method_chain :respond_to?, :attributes
      end
    end
    
    def method_missing_with_attributes(method_id, *args, &block)
      if attribute_names.include? attr_name = method_id.to_s
        read_attribute(attr_name, *args, &block)
      elsif attribute_names.include? attr_name = method_id.to_s.sub('=', '')
        write_attribute(attr_name, *args, &block)                           
      elsif attribute_names.include? attr_name = method_id.to_s.sub('?', '')
        (!!read_attribute(attr_name, *args, &block) rescue false)
      else
        method_missing_without_attributes(method_id, *args, &block)
      end
    end
    
    def respond_to_with_attributes?(method_id)
      respond_to_without_attributes?(method_id) or attribute_names.include? method_id.to_s.sub(/\?|\=/,'')
    end
    
    def attributes
      attribute_names.inject({}) {|attrs, attr_name| attrs.merge(attr_name => (send(attr_name).dup rescue send(attr_name)))}
    end
    
    def attributes=(attrs)
      attrs.each {|attr_name, value| send("#{attr_name}=", (value.dup rescue value))}
    end
    
    def [](attr_name)
      read_attribute(attr_name)
    end

    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end
      
    module ClassMethods
      def attribute(*attr_names)
        read_inheritable_attribute(:attribute_names).push(*attr_names.collect{|a| a.to_s})
        read_inheritable_attribute(:attribute_names).uniq!
      end
    end
    
  protected
    def attributes_hash
      @attributes or @attributes = HashWithIndifferentAccess.new
    end
    
    def write_attribute(attr_name, value)
      raise ArgumentError, "'#{attr_name}' is not an attribute" unless attribute_names.include? attr_name.to_s
      attributes_hash[attr_name] = value
    end
    
    def read_attribute(attr_name)
      raise ArgumentError, "'#{attr_name}' is not an attribute" unless attribute_names.include? attr_name.to_s
      attributes_hash[attr_name]
    end
  end
end