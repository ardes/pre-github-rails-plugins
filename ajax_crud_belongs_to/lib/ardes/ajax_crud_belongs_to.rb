module Ardes
  module AjaxCrudBelongsTo
    module Controller  
      def ajax_crud_belongs_to(association = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrudBelongsTo::Controller::InstanceMethods)
          raise 'ajax_crud_belongs_to requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include InstanceMethods
          extend ClassMethods
          class_inheritable_accessor :belongs_to_associations
          self.belongs_to_associations = []
          
          inherit_views 'ajax_crud_belongs_to'
          view_mapping 'ajax_crud_belongs_to' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))
          
          before_filter :load_belongs_to
        end
        
        add_belongs_to_association(association, options) if association
      end
  
      module InstanceMethods  
        def self.included(base)
          base.hide_action(*self.public_instance_methods)
          base.class_eval do
            alias_method_chain :edit,            :belongs_to
            alias_method_chain :default_params,  :belongs_to
            alias_method_chain :load_model_list, :belongs_to
          end
        end

        def edit_with_belongs_to
          params[self.model_sym].merge!(belongs_to_conditions) if params[self.model_sym]
          edit_without_belongs_to
        end    

        def default_params_with_belongs_to
          default_params_without_belongs_to.merge(belongs_to_conditions)
        end
    
      protected
        def belongs_to_object(sym)
          instance_variable_get("@#{sym}")
        end
        
        def belongs_to_conditions
          conditions = {}
          self.belongs_to_associations.each do |assoc|
            if assoc[:exclusive]
              conditions[assoc[:id_field]]   = belongs_to_object(assoc[:sym]).id
              conditions[assoc[:type_field]] = belongs_to_object(assoc[:sym]).class.name if assoc[:type_field]
            end
          end
          conditions
        end
        
        def load_model_list_with_belongs_to
          find_options = { :conditions => belongs_to_conditions }
          find_options.delete(:conditions) if find_options[:conditions].size == 0
          self.model_class.with_scope(:find => find_options) do
            load_model_list_without_belongs_to
          end
        end
          
        def load_belongs_to
          belongs_to_associations.each do |assoc|
            begin
              belongs_to_class = assoc[:class] || params[assoc[:type_field]].constantize
              instance_variable_set "@#{assoc[:sym]}", belongs_to_class.find(params[assoc[:id_field]])
            rescue Exception => e
              raise e if assoc[:exclusive]
            end
          end
        end
      end
  
      module ClassMethods
        def add_belongs_to_association(association, options = {})
          assoc = {}
          assoc[:sym]       = association
          assoc[:exclusive] = options[:exclusive].nil? ? true : options[:exclusive]
          assoc[:id_field]  = association.to_s.foreign_key.to_sym
          assoc[:find]      = options[:find].freeze || {}.freeze
          if options[:polymorphic]
            assoc[:type_field] = "#{association}_type".to_sym
          else
            assoc[:class] = association.to_s.classify.constantize
          end
          self.belongs_to_associations << assoc
        end
        
        def controller_id(url = {})
          controller_id = controller_name
          belongs_to_associations.each do |assoc|
            controller_id += "_#{url[:params][assoc[:id_field]]}"
            controller_id += "_#{url[:params][assoc[:type_field]]}" if assoc[:type_field]
          end
          controller_id
        end
      end
    end
  end
end
