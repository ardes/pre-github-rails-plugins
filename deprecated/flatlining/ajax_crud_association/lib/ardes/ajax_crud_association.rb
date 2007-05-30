module Ardes
  module AjaxCrudAssociation
    module Controller  
      def ajax_crud_association(association = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrudAssociation::Controller::InstanceMethods)
          raise 'ajax_crud_association requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include InstanceMethods
          extend ClassMethods
          cattr_accessor :associations
          self.associations = ::ActiveSupport::OrderedHash.new
          
          inherit_views 'ajax_crud_association', :at => 'ajax_crud'
          view_mapping 'ajax_crud_association' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))
          
          helper Helper
        end
        
        add_association(association, options) if association
      end
      
      module InstanceMethods
      end
      
      module ClassMethods
        def add_association(association, options = {})
          assoc_options = {}

          assoc_options[:class] = association.to_s.singularize.classify.constantize
          assoc_options[:display] = options[:display] || association.to_s.humanize.downcase
          assoc_options[:singular] = association.to_s.singularize.to_sym
          assoc_options[:id_field] = self.model_sym.to_s.foreign_key.to_sym
          assoc_options[:find] = options[:find] || {}
          
          create_association_actions(association, assoc_options)
          self.associations[association] = assoc_options
        end
      end
      
      def create_association_actions(assoc, options)
        self.class_eval do
          define_method "edit_#{assoc}" do
            find_model(params[:id])
            @association = assoc
            instance_variable_set("@#{assoc}", options[:class].find(:all, options[:find]))
            instance_variable_set("@#{model_sym}_#{assoc}", model_object.send(assoc))
            
            ajax_crud_options[:partial] = "edit_#{assoc}"
            ajax_crud_options[:partial] = 'edit_association' unless template_exists?("#{self.class.controller_path}/_#{ajax_crud_options[:partial]}")
            ajax_crud_options[:associated_partial] = "associated_#{options[:singular]}"
            ajax_crud_options[:associated_partial] = 'associated' unless template_exists?("#{self.class.controller_path}/_#{ajax_crud_options[:associated_partial]}")
            
            render :action => 'open.rjs'
          end
        
          define_method "update_#{options[:singular]}" do
            find_model(params[:id])
            @association = assoc
            @association_candidate = options[:class].find(params[options[:id_field]])
            instance_variable_set("@#{model_sym}_#{assoc}", model_object.send(assoc))
            
            if params[:add]
              model_object.send(assoc) << @association_candidate
            elsif params[:remove]
              model_object.send(assoc).delete @association_candidate
            end
            
            ajax_crud_options[:associated_partial] = "associated_#{options[:singular]}"
            ajax_crud_options[:associated_partial] = 'associated' unless template_exists?("#{self.class.controller_path}/_#{ajax_crud_options[:associated_partial]}")
            
            render :action => 'update_association.rjs'
          end
        end
      end
    end
    
    module Helper
      def association_link(assoc, obj)
        options = controller.associations[assoc]
        open_action_link(options[:display], {:action => "edit_#{assoc}", :id => obj.id})
      end
      
      def association_links(obj)
        controller.associations.keys.inject('') do |out, assoc|
          out << association_link(assoc, obj) + ' '
        end
      end
      
      def toggle_association_link(obj, on_html = nil, off_html = nil)
        on_html  = "<code>+</code> <strong>#{controller.model_desc(obj)}</strong>" unless on_html
        off_html = "<code>-</code> #{controller.model_desc(obj)}" unless off_html
        
        assoc = controller.model_object.send(@association)
        options = {:url => {:action => "update_#{@association.to_s.singularize}", :id => controller.model_object.id}}
        options[:url][:params] = {controller.associations[@association][:id_field] => obj.id}
        html = {:class => 'toggle'}
        if assoc.include? obj
          html[:title] = "Click to remove #{controller.model_desc(obj)} from #{controller.model_desc}"
          options[:url][:params][:remove] = true
          loading_link on_html, options.merge(:action => "remove_#{@association}"), html
        else
          html[:title] = "Click to add #{controller.model_desc(obj)} to #{controller.model_desc}"
          options[:url][:params][:add] = true
          loading_link off_html, options.merge(:action => "add_#{@association}"), html
        end
      end
    end
  end
end
