module Ardes
  module AjaxCrudHasMany
    module Controller  
      def ajax_crud_has_many(association = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrudHasMany::Controller::InstanceMethods)
          raise 'ajax_crud_has_many requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include InstanceMethods
          extend ClassMethods
          cattr_accessor :has_many_associations
          self.has_many_associations = ::ActiveSupport::OrderedHash.new
          
          inherit_views 'ajax_crud_has_many', :at => 'ajax_crud'
          view_mapping 'ajax_crud_has_many' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))
          
          helper Helper
        end
        
        add_has_many_association(association, options) if association
      end
  
      module InstanceMethods
      end
  
      module ClassMethods
        def add_has_many_association(association, options = {})
          assoc_options = {}

          assoc_options[:class] = association.to_s.singularize.classify.constantize
          assoc_options[:display] = options[:display] || association.to_s.humanize.downcase
          
          if options[:as]
            assoc_options[:id_field] = options[:as].to_s.foreign_key.to_sym
            assoc_options[:type_field] = "#{options[:as]}_type".to_sym
          else
            assoc_options[:id_field] = self.model_sym.to_s.foreign_key.to_sym
          end

          assoc_options[:controller] = options[:controller] || association
          assoc_options[:action] = options[:controller] || 'index'
          
          self.has_many_associations[association] = assoc_options
        end
      end      
    end
    
    module Helper
      def has_many_link(assoc, obj)
        assoc_options = controller.has_many_associations[assoc]
        options = {:controller => assoc_options[:controller], :action => assoc_options[:action]}
        options[assoc_options[:id_field]] = obj.id
        options[assoc_options[:type_field]] = obj.class.name if assoc_options[:type_field]
        options[:append_id] = public_id(:id => obj.id)
        open_action_link(assoc_options[:display], options)
      end
      
      def has_many_links(obj)
        controller.has_many_associations.keys.inject('') do |out, assoc|
          out << has_many_link(assoc, obj) + ' '
        end
      end
    end
  end
end
