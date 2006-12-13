module ActiveRecord#:nodoc:
  module Singleton
    # This mixin makes your ActiveRecord a singleton properties container.  There is only ever one row in the table
    # and accessing the properties on the class selects/updates that row with each access.
    # 
    # Usage:
    #
    #   class PropertyStore < ActiveRecord::Base
    #     include ActiveRecord::Singleton::Properties
    #   end
    # 
    #   PropertyStore.name = "fred" # => updates name property in the row in the table
    #   PropertyStore.instance      # => an instance which contains the row
    #
    # Use Case: <em>meta-data for another ActiveRecord</em>
    #
    #   class Focusable < ActiveRecord::Base
    #     acts_as_list
    #   
    #     class Properties < ActiveRecord::Base
    #       include ActiveRecord::Singleton::Properties
    #       self.table_name = 'focusable_properties'
    #     end
    #
    #     after_save {|record| Properties.focus_id = record.id}
    #
    #     def recieve_focus
    #       Properties.focus_id = self.id
    #     end
    #
    #     self.in_focus
    #       find Properties.focus_id
    #     end
    #   end
    # 
    module Properties
      def self.included(base)
        base.class_eval do
          unless included_modules.include? ::ActiveRecord::Singleton
            require 'active_record/singleton'
            include ::ActiveRecord::Singleton
          end
          extend ClassMethods
        end
      end
      
      def write_property(name, value)
        update_attributes self.class.read_singleton_attributes.merge(name.to_s => value)
      end
      
      
      def read_property(name)
        reload
        send name
      end
      
      module ClassMethods
        def self.extended(base)
          base.class_eval do
            class<<base
              alias_method_chain :respond_to?, :singleton_properties
              alias_method_chain :method_missing, :singleton_properties
            end
          end
        end
        
        def content_column_names
          instance_variable_get("@content_column_names") or instance_variable_set("@content_column_names", content_columns.map {|column| column.name })
        end
          
        def respond_to_with_singleton_properties?(method)
          respond_to_without_singleton_properties?(method) || content_column_names.include?(method.to_s.sub(/(=|\?)$/,''))
        end
        
        def method_missing_with_singleton_properties(method, *args)
          if content_column_names.include?(property = method.to_s.sub(/(=|\?)$/,''))
            case $1
            when "?" then return !!instance.read_property(property, *args)
            when "=" then return instance.write_property(property, *args)
            else          return instance.read_property(property, *args)
            end
          end
          method_missing_without_singleton_properties(method, *args)
        end
      end
    end
  end
end