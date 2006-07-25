module Ardes
  module AjaxCrudHasMany
    module Controller  
      def ajax_crud_has_many(association = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrudHasMany::Controller::InstanceMethods)
          raise 'ajax_crud_has_many requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include InstanceMethods
          extend ClassMethods
          class_inheritable_accessor :has_many_associations
          self.has_many_associations = []
          
          inherit_views 'ajax_crud_has_many'
          view_mapping 'ajax_crud_has_many' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))
          
          helper Helper
        end
        
        add_has_many_association(association, options) if association
      end
  
      module InstanceMethods
      end
  
      module ClassMethods
        def add_has_many_association(association, options = {})
          assoc = {}
          assoc[:sym] = association
          if options[:as]
            assoc[:id_field] = options[:as].to_s.foreign_key.to_sym
            assoc[:type_field] = "#{options[:as]}_type".to_sym
          else
            assoc[:id_field] = self.model_sym.to_s.foreign_key.to_sym
          end
          assoc[:display] = options[:display] if options[:display]
          self.has_many_associations << assoc
        end
      end
    end
    
    module Helper
      def has_many_links(obj)
        out = ''
        controller.has_many_associations.each do |assoc|
          options = {}
          options[:controller]        = assoc[:sym].to_s
          options[:action]            = 'index'
          options[assoc[:id_field]]   = obj.id
          options[assoc[:type_field]] = obj.class.name if assoc[:type_field]
          options[:container_id]      = public_id(:id => obj.id)
          out << open_action(assoc[:display] || assoc[:sym].to_s, options) + ' '
        end
        out
      end
    end
  end
end
