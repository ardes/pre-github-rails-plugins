require 'ardes/ajax_crud/helper_effects'

module Ardes
  module AjaxCrud
    module Helper
      include HelperEffects
      
      def loading_link(content, options = {}, html_options = {})
        options_add_loading(options, "#{public_id}_loading")
        options_add_confirm(html_options) if options.delete(:safe)
        link_to_remote(content, options, html_options)
      end
      
      def internal_link(content, options = {}, html_options = {})
        options[:url] = internal_url(options[:url])
        loading_link(content, options, html_options)
      end
      
      def internal_url(url)
        controller.internal_url(url)
      end
        
      def safe_link_to(content, options = {}, html_options = {})
        options_add_confirm(html_options)
        link_to(content, options, html_options)
      end

      def open_action(content, url, options = {})
        html_options = options.delete(:html) || {}
        html_options[:class] = options.delete(:class) || 'action'
        options_add_loading(options, "#{public_id}_loading")
        options[:url] = internal_url(url)
        action_id = public_id(url);
        options[:before] = enable_action_link(false, action_id)
        create_action_link(action_id, content, options, html_options)
      end

      def cancel_action(content, url, options = {})
        html_options = options.delete(:html) || {}
        html_options[:class] = options.delete(:class) || 'action'
        options_add_confirm(html_options) if options.delete(:safe)
        options_add_loading(options, "#{public_id}_loading")
        url[:params] ||= {}
        url[:params][:cancel] = url.delete(:action)
        url[:action] = 'cancel'
        options[:url] = internal_url(url)
        link_to_remote(content, options, html_options)
      end

      def form_for_action(url, options = {}, &block)
        options_add_loading(options, "#{public_id}_loading")
        options[:url] = internal_url(url)
        options[:before] = disable_form(public_id(url) + '_form')
        options[:html] ||= {}
        options[:html][:id] = "#{public_id(url)}_form"
        options[:builder] ||= Ardes::AjaxCrud::FormBuilder
        object_name = options.delete(:object_name) || controller.model_sym
        object = options.delete(:object) || controller.model_object
        form_remote_for(object_name, object, options, &block)
      end

      def public_id(url = {})
        if url[:controller] && url[:controller] != controller.controller_name
          controller_class = "#{url[:controller]}_controller".classify.constantize
          controller_class.public_id(url)
        else
          controller.public_id(url)
        end
      end
      
      def rjs_message(page, message, options = {})
        message_div = "#{public_id(options)}_message"
        page.replace_html message_div, message.to_s
        page.message message_div
      end

      def rjs_open(page, options)
        action_id = public_id(options)
        action = options.delete(:action)
        container_id = options.delete(:container_id) || public_id(options)
        page.action_create container_id, action_id
        page.replace_html action_id, :partial => action
        page.action_open action_id
      end

      def rjs_close(page, options)
        page.action_close public_id(options)
      end

      def rjs_error(page, options)
        action_id = public_id(options)
        page.replace_html action_id, :partial => options[:action]
        page.action_error action_id
      end

      def rjs_update_item(page, item, new_record, options = {})
        if new_record # append to list
          rjs_append_item(page, item, options)
        else # update item in list
          rjs_refresh_item(page, item, options)
        end
      end
      
      def rjs_remove_item(page, item, options = {})
        list_id = "#{public_id(options)}_list"
        options[:id] = item.id
        item_id = "#{public_id(options)}_item"
        
        page.insert_html :top, list_id, :partial => "list_empty" if controller.model_list(reload = false).size == 1 
        page.remove item_id
        page.list_changed list_id
      end
        
      def rjs_refresh_item(page, item, options = {})
        options[:id] = item.id
        item_id = "#{public_id(options)}_item"
        item_main_id = "#{item_id}_main"
        page.replace_html item_main_id, :partial => 'item_main', :locals => {:item => item}
        page.item_changed item_id
      end

      def rjs_append_item(page, item, options = {})
        public_id = public_id(options)
        
        list_id  = "#{public_id}_list"
        empty_id = "#{public_id}_list_empty"
        end_id   = "#{public_id}_list_end"
        
        options[:id] = item.id
        item_id = "#{public_id(options)}_item"

        page.remove end_id
        page.remove empty_id if controller.model_list(reload = false) == 0
        
        page.insert_html :bottom, list_id, :partial => 'item', :locals => {:item => item}
        page.insert_html :bottom, list_id, :partial => 'list_end'
        page.item_changed item_id
      end
    end
  end
end