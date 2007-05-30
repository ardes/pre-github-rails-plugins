module Ardes
  module AjaxCrudHasOne
    module Controller  
      def ajax_crud_has_one(association = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrudHasOne::Controller::InstanceMethods)
          raise 'ajax_crud_has_one requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include InstanceMethods
          extend ClassMethods
          cattr_accessor :has_one_associations
          self.has_one_associations = ::ActiveSupport::OrderedHash.new
          
          inherit_views 'ajax_crud_has_one', :at => 'ajax_crud'
          view_mapping 'ajax_crud_has_one' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))
          
          helper Helper
        end
        
        add_has_one_association(association, options) if association
      end
  
      module InstanceMethods
      end
  
      module ClassMethods
        def add_has_one_association(association, options = {})
          assoc_options = {}
          
          if options[:as]
            assoc_options[:id_field] = options[:as].to_s.foreign_key.to_sym
            assoc_options[:type_field] = "#{options[:as]}_type".to_sym
          else
            assoc_options[:id_field] = self.model_sym.to_s.foreign_key.to_sym
          end

          assoc_options[:display]     = options[:display] || association.to_s.humanize.downcase
          assoc_options[:controller]  = options[:controller] || association.to_s.pluralize
          assoc_options[:action]      = options[:action] || 'panel'
          assoc_options[:action_new]  = options[:action_new] || 'new'
          
          self.has_one_associations[association] = assoc_options
        end
      end      
    end
    
    module Helper
      def has_one_link(assoc, obj)
        assoc_options = controller.has_one_associations[assoc]
        options = {:controller => assoc_options[:controller]}
        
        if target = obj.send(assoc)
          options[:action] = assoc_options[:action]
          options[:id] = target.id
        else
          options[:action] = assoc_options[:action_new]
        end
        
        options[assoc_options[:id_field]] = obj.id
        options[assoc_options[:type_field]] = obj.class.name if assoc_options[:type_field]
        
        options[:append_id] = public_id(:id => obj.id)
        open_action_link(assoc_options[:display], options)
      end
      
      def has_one_links(obj)
        controller.has_one_associations.keys.inject('') do |out, assoc|
          out << has_one_link(assoc, obj) + ' '
        end
      end
    end
  end
end
