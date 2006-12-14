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
    #   PropertyStore.winner = "fred" # => updates winner property in the row in the table
    #   PropertyStore.winner          # => selects winner attribute from the row in the table
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
    # Note: if you want to read some properties with a pessimistic lock then lock the instance
    # and use the instance attributes.  For example:
    # 
    #   transaction do
    #     PropertyStore.instance.lock!
    #     User.find PropertyStore.instance.winner
    #     User.so_something_to_winner
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
      
      # write the named property with a single column update
      def write_property(name, value)
        column = column_for_attribute(name)
        connection.update "UPDATE #{self.class.table_name} SET #{column.name}=#{quote_value(value, column)}", "#{self.class.name} Write Property"
        send "#{name}=", value
      end
      
      # read the named property into attributes with a single column select and return the attribute
      def read_property(name, options = {})
        instance_variable_get("@attributes")[name] = connection.select_value "SELECT #{column_for_attribute(name).name} FROM #{self.class.table_name} LIMIT 1 #{options[:lock] ? ' FOR UPDATE' : ''}", "#{self.class.name} Read Property"
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
            define_property_accessors
            send(method, *args)
          else
            method_missing_without_singleton_properties(method, *args)
          end
        end
        
      protected
        def define_property_accessors
          meta = class<<self;self;end
          inner = 0
          content_column_names.each do |property|
            raise "Conflicting property name '#{property}'" if meta.instance_methods.include? property
            meta.class_eval <<-end_eval
              def #{property}(options = {});  instance.read_property('#{property}', options); end
              def #{property}?(options = {}); !!instance.read_property('#{property}', options); end
              def #{property}=(value);        instance.write_property('#{property}',value); end
            end_eval
          end
        end
      end
    end
  end
end