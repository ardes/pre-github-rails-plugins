require 'ardes/ajax_crud/helper'
require 'ardes/ajax_crud/page_helper'

module Ardes
  module AjaxCrud
    module Controller
      def ajax_crud(model = nil, options = {})
        unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
          include Actions
          include InstanceMethods
          extend ClassMethods

          assets_in_views

          class_inheritable_accessor :model_sym, :model_class, :model_name, :model_list_sym, :model_find_options
        
          helper Ardes::AjaxCrud::Helper
          helper Ardes::AjaxCrud::PageHelper
        
          inherit_views 'ajax_crud', :at => :end
          view_mapping 'ajax_crud' => File.expand_path(File.join(File.dirname(__FILE__), '../../../views'))
        
          layout 'ajax_crud/_layout'
          
          before_filter :extract_ajax_crud_options
        end
        
        ajax_crud_model(model, options) if model
      end

      module Actions
        def index
          model_list
          respond_to do |type|
            type.html { render :action => 'index.rhtml' }
            type.js   { ajax_crud_options[:child] = true; render :action => 'open' }
          end
        end
        
        # opens a panel where 'show' and 'edit' may be called, defaults to 'show'
        def panel
          find_model(params[:id])
          params[:panel_action] ||= 'show'
          params[:in_panel] = true
          
          # these params will be passed to all links in the rendering of the panel
          url_options[:in_panel] = true
          url_options[:replace] = 'panel'
          url_options[:on_complete] = params[:panel_default] || params[:panel_action]
        end
        
        def show
          find_model(params[:id])
        end
        
        def destroy
          if find_model(params[:id]).destroy
            flash[:info] = "#{model_desc} destroyed"
          else
            flash[:error] = "error destroying #{model_desc}"
          end
        end
        
        def edit
          find_model(params[:id])
        end
        
        def new
          new_model
        end
        
        def update
          if find_model(params[:id]).update_attributes(params[model_sym])
            flash[:info] = "#{model_desc} updated"
          else
            flash[:error] = "error updating #{model_desc}"
          end
        end
        
        def create
          if new_model.update_attributes(params[model_sym])
            flash[:info] = "#{model_desc} created"
          else
            flash[:error] = "error creating new #{model_name}"
          end
        end
      end
      
      module InstanceMethods
        def self.included(base)
          base.hide_action self.public_instance_methods
          base.class_eval do
            alias_method_chain :perform_action_without_rescue, :ajax_crud
            alias_method_chain :rewrite_options, :ajax_crud
          end
        end

        # default template is open.rjs if none is found matching the action name
        def perform_action_without_rescue_with_ajax_crud
          perform_action_without_rescue_without_ajax_crud
        rescue ::ActionController::MissingTemplate
          render :action => 'open'
        end
        
        def public_id(url = {})
          self.class.public_id(default_url_options.merge(url))
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
        
        def url_options
          @ajax_crud_url_options ||= {}
        end
        
        def ajax_crud_options
          @ajax_crud_options ||= {}
        end
        
      protected
        def extract_ajax_crud_options
          ajax_crud_options[:action]      = action_name
          ajax_crud_options[:replace_id]  = params.delete(:ajax_crud_replace_id)
          ajax_crud_options[:append_id]   = params.delete(:ajax_crud_append_id)
          ajax_crud_options[:action_id]   = params.delete(:ajax_crud_action_id)
          ajax_crud_options[:on_complete] = YAML.load(params.delete(:ajax_crud_on_complete).to_s)
          # :on_complete passes through to the next action, unless specified otherwise (:on_complete => nil/false)
          url_options[:on_complete] = ajax_crud_options[:on_complete]
          true
        end
      
        def find_model(id)
          instance_variable_set("@#{model_sym}", model_class.find(id, model_find_options.dup))
        end                                      
                                                 
        def new_model                       
          instance_variable_set("@#{model_sym}", model_class.new)
        end
      
        def find_or_new_model(id = nil)
          return find_model(id)
        rescue ::ActiveRecord::RecordNotFound
          return new_model
        end

        def load_model_list
          model_class.find :all, model_find_options.dup
        end
        
        def default_url_options(options = {})
          url_options
        end
        
        def rewrite_options_with_ajax_crud(options)
          options = rewrite_options_without_ajax_crud(options)
          options = build_target_ids_in_url(options)
          options = build_on_complete_in_url(options)
        end
        
        def build_target_ids_in_url(url)
          [:replace, :append].each do |target|
            if loc = url.delete(target)
              url["ajax_crud_#{target}_id".to_sym]  = public_id(:id => url[:id])
              url["ajax_crud_#{target}_id".to_sym] += "_#{loc}" if loc.is_a?(String)
            end
            url["ajax_crud_#{target}_id".to_sym] = url.delete("#{target}_id".to_sym) if url.key?("#{target}_id".to_sym)
          end
          url[:ajax_crud_action_id] = url.delete(:action_id) if url.key?(:action_id)
          url
        end

        def build_on_complete_in_url(url)
          if url.key?(:on_complete)
            if on_complete = url.delete(:on_complete)
              if on_complete.is_a?(String) # build using the url
                on_complete = {:action => on_complete}
                on_complete.reverse_merge!(url)
              end
              build_target_ids_in_url(on_complete)
              url[:ajax_crud_on_complete] = on_complete.to_yaml
            else
              url[:ajax_crud_on_complete] = nil
            end
          end
          url
        end
      end
    
      module ClassMethods
        def ajax_crud_model(model_sym, find_options = {})
          self.model_sym          = model_sym
          self.model_name         = model_sym.to_s.humanize.downcase
          self.model_class        = model_sym.to_s.pluralize.classify.constantize
          self.model_list_sym     = model_sym.to_s.pluralize.to_sym
          self.model_find_options = find_options.freeze
        end
        
        def public_id(url = {})
          public_id = controller_id(url)
          public_id += "_#{url[:action]}"      if url[:action]
          if id = url[:id] || (url[:params][:id] rescue nil)
            public_id += "_#{id}"
          end
          public_id
        end
        
        def controller_id(url = {})
          self.controller_name
        end
      end
    end
  end
end