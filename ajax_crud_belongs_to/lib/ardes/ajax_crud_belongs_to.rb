module Ardes# :nodoc:
  # 
  # Specify this to add belongs_to functionality to this controller.  Example:
  #
  #   class FooController < ApplicationController
  #     ajax_crud_belongs_to :bar 
  #   end
  #
  # The above controller will expect bar_id among the params (and will propagate
  # bar_id in all internal links).  The controller will show all foos belonging
  # to the particular bar.
  #
  module AjaxCrudBelongsTo
    module Controller
      # Make controller show models belonging to the specified model
      #
      # == Configuration Options
      #
      # * <tt>:polymorphic</tt> - belongs to a polymorphic relation (default false)
      #
      def ajax_crud_belongs_to(association = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrudBelongsTo::Controller::InstanceMethods)
          raise 'ajax_crud_belongs_to requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include InstanceMethods
          extend ClassMethods
          cattr_accessor :belongs_to_associations
          self.belongs_to_associations = ::ActiveSupport::OrderedHash.new
          
          inherit_views 'ajax_crud_belongs_to', :at => 'ajax_crud'
          view_mapping 'ajax_crud_belongs_to' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))
          
          before_filter :load_belongs_to
        end
        add_belongs_to_association(association, options) if association
      end
  
      module InstanceMethods  
        def self.included(base)
          base.hide_action(*self.public_instance_methods)
          base.class_eval do
            alias_method_chain :update,              :belongs_to
            alias_method_chain :create,              :belongs_to
            alias_method_chain :default_url_options, :belongs_to
            alias_method_chain :load_model_list,     :belongs_to
          end
        end

        def update_with_belongs_to
          params[self.model_sym].merge!(belongs_to_conditions)
          update_without_belongs_to
        end
        
        def create_with_belongs_to
          params[self.model_sym].merge!(belongs_to_conditions)
          create_without_belongs_to
        end

        def default_url_options_with_belongs_to(options = {})
          default_url_options_without_belongs_to.merge(belongs_to_conditions)
        end
    
        def belongs_to_object(sym)
          instance_variable_get("@#{sym}")
        end
        
      protected
        def belongs_to_conditions
          self.belongs_to_associations.inject({}) do |conditions, (assoc, options)|
            if belongs_to_object(assoc)
              conditions[options[:id_field]]   = belongs_to_object(assoc).id
              conditions[options[:type_field]] = belongs_to_object(assoc).class.name if options[:type_field]
            end
            conditions
          end
        end
                
        def load_model_list_with_belongs_to
          options = (conditions = belongs_to_conditions).size > 0 ? {:conditions => conditions} : {}
          self.model_class.with_scope(:find => options) do
            load_model_list_without_belongs_to
          end
        end
          
        def load_belongs_to
          belongs_to_associations.each do |assoc, options|
            belongs_to_class = options[:class] || params[options[:type_field]].constantize
            instance_variable_set "@#{assoc}", belongs_to_class.find(params[options[:id_field]])
          end
        rescue
          true
        end
      end
  
      module ClassMethods
        def add_belongs_to_association(assoc, options = {})
          assoc_options = {}
          assoc_options[:id_field]    = assoc.to_s.foreign_key.to_sym
          if options[:polymorphic]
            assoc_options[:type_field] = "#{assoc}_type".to_sym
          else
            assoc_options[:class] = assoc.to_s.classify.constantize
          end
          self.belongs_to_associations[assoc] = assoc_options
        end
        
        def controller_id(url = {})
          controller_id = controller_name
          belongs_to_associations.each do |assoc, options|
            controller_id += "_#{url[options[:id_field]]}"
            controller_id += "_#{url[options[:type_field]]}" if options[:type_field]
          end
          controller_id
        end
      end
    end
  end
end
