module ActiveRecord#:nodoc:
  # Mixin to make an ActiveRecord class behave in a singleton fashion, having
  # only one row in its associated table.
  #
  # ActiveRecord::Sinigleton does not, by its nature, support STI (single table inheritance).
  #
  # A Singleton still has a primary key id column, for the following reasons:
  # * the ActiveRecord finders and updaters will work untouched, and
  # * so you can reference the singleton record from other classes (or if the singleton record
  # might have a has_many relationship) in the usual way.
  #
  # The finders work as expected, but always return the same object (if it is found).
  # 
  # You cannot call destroy on a singleton object
  #
  # You cannot instantiate a Singleton object with <tt>new</tt>, use <tt>instance</tt> or <tt>find</tt>
  #
  # ActiveRecord::Singleton is Thread safe, and handles concurrent access properly (if two separate processes
  # instantiate a Singleton where a table is empty, only one row will be created)
  module Singleton
    def self.included(base)
      require 'singleton'
      base.class_eval do
        include ::Singleton
        extend ClassMethods
        alias_method_chain :initialize, :singleton
        protected :destroy
       end
    end
    
    # initializing the instance finds the first (only) record, if the record does not exist
    # then one is created (without validation).  This happens within a transaction with a lock
    # to ensure that two different processes do not create two new singleton rows.
    def initialize_with_singleton(*args)
      initialize_without_singleton(*args)
      transaction do
        if attributes = self.class.read_singleton_attributes
          instance_variable_set("@attributes", attributes)
          instance_variable_set("@new_record", false)
        else
          self.save(false)
        end
      end
    end
    
    module ClassMethods
      def read_singleton_attributes
        connection.select_one("SELECT * FROM #{table_name} LIMIT 1 FOR UPDATE")
      end
      
      def instantiate(record)
        instance.instance_variable_set("@attributes", record) unless instance_variable_get("@__instance__")
        instance
      end
    end
  end
end