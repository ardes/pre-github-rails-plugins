require 'ardes/ajax_crud/helper'

module Ardes
  module AjaxCrud
    module Controller
      def ajax_crud(model = nil, options = {})
        include Actions
        include InstanceMethods
        extend ClassMethods

        class_inheritable_accessor :model_sym, :model_class, :model_name, :model_list_sym, :model_find_options
        ajax_crud_model(model, options) if model
        
        helper Ardes::AjaxCrud::Helper
        
        inherit_views 'ajax_crud'
        view_mapping 'ajax_crud' => File.expand_path(File.join(File.dirname(__FILE__), '../../../views'))
        
        layout 'ajax_crud/layouts/ajax_crud'
      end

      module Actions
        def index
          model_list
          respond_to(:html, :js)
        end
        
        def show
          find_model(params[:id])
          render :action => 'open'
        end
        
        def destroy
          obj = find_model(params[:id])
          if obj.destroy
            @message = "#{model_desc} destroyed"
          end
        end
        
        def edit
          obj = self.find_or_new_model(params[:id])
          @new_record = obj.new_record?
          if params[self.model_sym]
            obj.attributes = params[self.model_sym]
            if obj.save
              @message = model_desc + (@new_record ? ' created' : ' updated')
              render :action => 'edit'
            else
              render :action => 'error'
            end
          else
            render :action => 'open'
          end
        end
      end
      
      module InstanceMethods
        def self.included(base)
          methods = self.public_instance_methods
          base.class_eval { hide_action(*methods) }
        end

        def public_id(url = {})
          self.class.generate_public_id(internal_url(url))
        end

        def model_desc(model = model_object)
          model.respond_to?(:obj_desc) ? model.obj_desc : "#{model_name}: #{model.id}"
        end
        
        def model_object
          instance_variable_get("@#{model_sym}")
        end
        
        def model_list(reload = false)
          instance_variable_set("@#{model_list_sym}", load_model_list) if reload or instance_variable_get("@#{model_list_sym}").nil?
          instance_variable_get("@#{model_list_sym}")
        end
        
        def internal_url(url)
          url = self.class.sanitize_url(url)
          url[:params].merge!(default_params)
          url
        end
      
      protected
        def find_model(id)
          instance_variable_set("@#{model_sym}", model_class.find(id, model_find_options.dup))
        end                                      
                                                 
        def new_model                            
          instance_variable_set("@#{model_sym}", model_class.new)
        end
      
        def find_or_new_model(id = nil)
          id = nil if id == "new"
          return find_model(id)
        rescue ::ActiveRecord::RecordNotFound
          return new_model
        end

        def load_model_list
          model_class.find :all, model_find_options.dup
        end
        
        def default_params
          {}
        end
      end
    
      module ClassMethods
        def ajax_crud_model(model_sym, find_options = {})
          self.model_sym          = model_sym
          self.model_name         = model_sym.to_s.humanize.downcase
          self.model_class        = model_sym.to_s.classify.constantize
          self.model_list_sym     = model_sym.to_s.pluralize.to_sym
          self.model_find_options = find_options.freeze
        end
        
        def public_id(url = {})
          generate_public_id(sanitize_url(url))
        end
        
        def sanitize_url(url)
          url = url.dup
          sanitized = {}
          sanitized[:controller] = url.delete(:controller) if url[:controller]
          sanitized[:action] = url.delete(:action) if url[:action]
          sanitized[:params] = url.delete(:params) || {}
          sanitized[:params].merge!(url)
          sanitized
        end
        
        def controller_id(url = {})
          self.controller_name
        end
        
        def generate_public_id(url)
          public_id  = controller_id(url)
          public_id += "_#{url[:params][:id]}" if url[:params][:id]
          public_id += "_#{url[:action]}"      if url[:action]
          public_id
        end
      end
    end
  end
end