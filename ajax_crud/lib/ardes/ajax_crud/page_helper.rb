module Ardes
  module AjaxCrud
    module PageHelper
      #
      # helpers for rjs that requuire controllers, takes page as first arg as controller does not seem accessible when you
      # make a page helper
      #
      
      def update_flash_in_page(page, options = {})
        message = nil
        [:info, :warning, :error].each do |key|
          if flash[key]
            message = "<span class=\"#{key}\">#{flash[key]}</span>"
            flash.discard(key)
          end
        end
        
        if message
          flash_id = "#{public_id(options)}_flash"
          page.if_id(flash_id) do
            page.replace_html flash_id, message
            page.display_flash flash_id
          end
        end
      end

      def open_action_in_page(page, options)
        action_id = options[:action_id] || public_id(options)
        content = render(:partial => options[:partial] || options[:action], :locals => {:model => controller.model_object})
        if options[:replace_id]
          page.create_action options[:replace_id], action_id, content, :replace => true
        else
          append_id = options[:append_id] || public_id(:id => options[:id])
          page.create_action append_id, action_id, content
        end
      end

      def close_action_in_page(page, options)
        page.remove_action(options[:action_id] || public_id(options))
      end

      def complete_action_in_page(page, options)
        if controller.ajax_crud_options[:on_complete]
          options = {:url => controller.ajax_crud_options[:on_complete]}
          action_add_loading(options)
          page << remote_function(options)
        else
          close_action_in_page page, options
        end
      end
      
      def action_error_in_page(page, options)
        action_id = options[:action_id] || public_id(options)
        page.replace_html action_id, :partial => options[:partial] || options[:action], :locals => {:model => controller.model_object}
        page.error_on_action action_id
      end
      
      def remove_item_in_page(page, item, options = {})
        list_id = "#{public_id(options)}_list"
        page.if_id(list_id) do
          page.insert_html :top, list_id, :partial => "list_empty" if controller.model_list.size == 0
          page.remove "#{public_id(options.merge(:id => item.id))}_item"
          page.list_changed list_id
        end
      end
        
      def refresh_item_in_page(page, item, options = {})
        item_id = "#{public_id(options.merge(:id => item.id))}_item"
        page.if_id(item_id) do
          item_main_id = "#{item_id}_main"
          page.replace_html item_main_id, :partial => 'item_main', :locals => {:item => item}
          page.item_changed item_id
        end
      end

      def append_item_in_page(page, item, options = {})
        public_id = public_id(options)
        list_id  = "#{public_id}_list"
        
        page.if_id(list_id) do
          empty_id = "#{public_id}_list_empty"
          end_id   = "#{public_id}_list_end"
          item_id  = "#{public_id(options.merge(:id => item.id))}_item"

          page.remove empty_id if controller.model_list.size == 1
          page.insert_html :before, end_id, :partial => 'item', :locals => {:item => item}
          page.item_changed item_id
        end
      end
      
      #
      # page helpers that don't access controller
      #
      def if_id(id, &block)
        page << "if ($('#{id}')) { "
        yield
        page << "}"
      end
  
      def display_flash(flash_id)
        page.delay(0.5) {page.visual_effect :appear, flash_id, {:duration => 0.5, :queue => {:position => 'end', :scope => flash_id}}}
        page.delay(3)   {page.visual_effect :fade,   flash_id, {:queue => {:position => 'end', :scope => flash_id}}}
      end
  
      def create_action(target_id, action_id, content, options = {})
        if options[:replace]
          page.finish_observing_action(target_id)
          page.replace_html target_id, "<div id=\"#{action_id}\" class=\"action\">#{content}</div>"
        else
          page.insert_html :top, target_id, "<div id=\"#{action_id}\" class=\"action\" style=\"display:none;\">#{content}</div>"
          page.visual_effect :blind_down, action_id, {:duration => 0.2}
        end
        page.observe_action(action_id)
        page.focus_on_action(action_id)
      end
  
      def remove_action(action_id)
        page.finish_observing_action(action_id)
        page.visual_effect :blind_up, action_id, {:duration => 0.2}
        page.delay(0.25) {page.remove action_id}
      end
  
      def focus_on_action(action_id)
        page.delay(0.25) {page << "ArdesAjaxCrud.focus('#{action_id}');" }
      end
  
      def observe_action(action_id)
        page.delay(0.25) {page << "ArdesAjaxCrud.observe('#{action_id}');"}
      end
  
      def finish_observing_action(action_id)
        page << "ArdesAjaxCrud.setAllCleanIn('#{action_id}');"
      end

      def error_on_action(action_id)
        page.visual_effect :highlight, action_id, {:duration => 0.25, :startcolor => '"#FFDDDD"', :queue => 'front'}
      end

      def list_changed(list_id)
        page.visual_effect :highlight, list_id
      end
  
      def item_changed(item_id)
        page.visual_effect :highlight, item_id
      end
    end
  end
end