module Ardes
  module AjaxCrud
    module HelperEffects
      def confirm_link_to
        "if (! ArdesAjaxCrud.confirm()) {return false;}"
      end
      
      def enable_action_link(enabled, action_id)
        out  = "Element.#{enabled ? 'show' : 'hide'}('#{action_id}_open');"
        out += "Element.#{enabled ? 'hide' : 'show'}('#{action_id}_goto');"
      end
      
      def create_action_link(action_id, content, options, html_options)
        out  = link_to_remote(content, options,
                  html_options.merge({:id => "#{action_id}_open"}))
        
        out += link_to_function(content,
                  "ArdesAjaxCrud.focus('#{action_id}');",
                  html_options.merge({:id => "#{action_id}_goto", :style => "display:none;"}))
      end
      
      def disable_form(form_id)
        "Form.disable('#{form_id}');"
      end
      
      #
      # options array
      #
      def options_add_confirm(options)
        options[:onclick] = "#{confirm_link_to}#{options[:onclick]}"
      end
      
      def options_add_loading(options, loading_id)
        options[:loading] ||= ''
        options[:loading] += "Element.show('#{loading_id}');"
        options[:loaded]  ||= ''
        options[:loaded]  += "Element.hide('#{loading_id}');"
      end
      
      #
      # page helpers
      #
      def message(message_id)
        page.delay(0.5) { page.visual_effect :appear, message_id, {:duration => 0.5, :queue => {:position => 'end', :scope => 'message'}}}
        page.delay(3)   { page.visual_effect :fade,   message_id, {:queue => {:position => 'end', :scope => 'message'}} }
      end
      
      def action_create(container_id, action_id)
        page.insert_html :top, container_id, "<div id=\"#{action_id}\" class=\"action\" style=\"display:none;\"></div>"
      end
      
      def action_open(action_id)
        page.visual_effect :blind_down, action_id, {:duration => 0.2}
        page.delay(0.25) do
          page << "ArdesAjaxCrud.focus('#{action_id}');"
          page << "ArdesAjaxCrud.observe('#{action_id}');"
        end
      end
      
      def action_close(action_id)
        page << "ArdesAjaxCrud.setClean('#{action_id}');"
        page << enable_action_link(true, action_id)
        page.visual_effect :blind_up, action_id, {:duration => 0.2}
        page.delay(0.25) { page.remove action_id }
      end

      def action_error(action_id)
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