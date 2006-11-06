module Ardes#:nodoc:
  # include this to specify attributes that an object has at the class level
  #
  # This is similar to attr_accessor, except:
  # * an attribute? method is added
  # * all attributes are stored in an instance variable hash @attributes
  # * attributes can be set en masse with an attributes accessor
  # * individual accessor methods added to the class with overwrite the
  #   default methods.  Use read_attribute, and write_attribute to set the
  #   attributes from within these methods.
  #
  # 
  # Example:
  #
  #   class Foo
  #     include Ardes::Attributes
  #     attributes :foo, "bar"
  #   end
  #
  #   f = Foo.new
  #   f.attribute_names # => ["foo", "bar"]
  # 
  module Attributes
    
    class MissingAttribute < RuntimeError; end
    
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        class_inheritable_reader :attribute_names
        write_inheritable_attribute(:attribute_names, [])
        alias_method_chain :method_missing, :attributes
        alias_method_chain :respond_to?, :attributes
      end
    end
    
    # optionally takes a hash of attributes
    def initialize(attrs = nil)
      instance_variable_set('@attributes', {})
      self.attributes = attrs if attrs
    end
    
    # default accessors for attributes are implemented here, (if 
    # you define an accessor method explicitly in the class, then
    # this will not be called)
    def method_missing_with_attributes(method_id, *args, &block)
      attr_name = method_id.to_s
      if attribute_names.include? attr_name
        read_attribute(attr_name, *args, &block)
      elsif attribute_names.include? attr_name.sub!('=', '')
        write_attribute(attr_name, *args, &block)
      elsif attribute_names.include? attr_name.sub!('?', '')
        (!!read_attribute(attr_name, *args, &block) rescue false)
      else
        method_missing_without_attributes(method_id, *args, &block)
      end
    end
    
    # complements method_missing
    def respond_to_with_attributes?(method_id)
      respond_to_without_attributes?(method_id) or attribute_names.include? method_id.to_s.sub(/\?|\=/,'')
    end
    
    # returns a hash of the attributes, with values duplicated
    # this hash is constructed using the reader methods if they exist
    def attributes
      attribute_names.inject({}) do |attrs, attr_name|
        value = send(attr_name)
        attrs.merge(attr_name => (value.dup rescue value))
      end
    end
    
    # sets the attributes using duplicates of the passed values
    def attributes=(attrs)
      attrs.each do |attr_name, value|
        begin
          send("#{attr_name}=", (value.dup rescue value))
        rescue NoMethodError
          raise MissingAttribute, "'#{attr_name}' is not an attribute of #{self.class.name}"
        end
      end
    end
    
    # gets an attribute dierctly - bypassing any reader method that might be defined
    def [](attr_name)
      read_attribute(attr_name)
    end

    # sets an attribute directlly, bypassing any writer method that might be defined
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end
    
    
    module ClassMethods
      # declares that the class is to have the specified attribute
      def attribute(*attr_names)
        read_inheritable_attribute(:attribute_names).push(*attr_names.collect{|a| a.to_s})
        read_inheritable_attribute(:attribute_names).uniq!
      end
    end
    
  protected
    def write_attribute(attr_name, value)
      raise MissingAttribute, "'#{attr_name}' is not an attribute of #{self.class.name}" unless attribute_names.include? attr_name = attr_name.to_s
      instance_variable_get('@attributes')[attr_name] = value
    end
    
    def read_attribute(attr_name)
      raise MissingAttribute, "'#{attr_name}' is not an attribute of #{self.class.name}" unless attribute_names.include? attr_name = attr_name.to_s
      instance_variable_get('@attributes')[attr_name]
    end
    
    # conforms to attributes interface, but attributes are specifed on a per
    # object basis.  This is useful for having an ad-hoc attributes object,  created
    # from a Hash.
    class Base
      include Attributes
      
      attr_reader :attribute_names
      
      def self.attribute
        raise Error, "cannot declare attribute at class level in #{self.class.name}"
      end
      
      def initialize(attrs = {})
        @attributes = {}        
        @attribute_names = []
        if attrs
          attribute(*attrs.keys)
          self.attributes = attrs
        end
      end
      
      def attribute(*attr_names)
        @attribute_names.push(*attr_names.collect{|a| a.to_s})
        @attribute_names.uniq!
      end
      
      alias :has_attribute :attribute
    end
  end
end