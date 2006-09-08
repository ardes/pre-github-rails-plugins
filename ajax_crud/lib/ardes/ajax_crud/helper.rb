module Ardes
  module AjaxCrud
    module Helper
      # create the link_to_remote with a wrapper that passes focus to the action_id if it already exists on the page
      def create_action_link(action_id, content, options, html_options = {})
        unless options[:url][:replace_id] == action_id
          html_options[:onclick] = "if($('#{action_id}')){ArdesAjaxCrud.focus('#{action_id}');return false;}#{options[:onclick]}"
        end
        link_to_remote(content, options, html_options)
      end
      
      def disable_form(form_id)
        "Form.disable('#{form_id}');"
      end
      
      #
      # options array
      #
      def options_add_confirm(options)
        options[:onclick] = "if (! ArdesAjaxCrud.confirm()) {return false;}#{options[:onclick]}"
      end
      
      def options_add_loading(options, loading_id)
        options[:loading] ||= ''
        options[:loading] += "if($('#{loading_id}')){Element.show('#{loading_id}');}"
        options[:loaded]  ||= ''
        options[:loaded]  += "if($('#{loading_id}')){Element.hide('#{loading_id}');}"
      end
      
      # renders a summary of an attribute of the current model object in the same
      # format as FormBuilder attributes
      def summary(attribute, options = {})
        object = options[:object] || controller.model_object
        label = options.delete(:label) || attribute.to_s.humanize
        tip = options.delete(:tip)
        tip = "<div class=\"tip\">#{tip}</div>" if tip
        <<-end_summary
          <div class="summary">
            <div class="label">#{label}:</div>
            <div class="content">#{object.send(attribute)} &nbsp;</div>
            #{tip}
          </div>
        end_summary
      end
      
      # turns the loading div on while the action is in progress
      # if options[:url][:id] is passed then that loading div is turned on as well
      # if :safe is true then the link is made a confirmation link if the 
      # page contains dirty forms
      def loading_link(content, options = {}, html_options = {})
        options_add_loading(options, "#{public_id}_loading")
        options_add_loading(options, "#{public_id(:id => options[:url][:id])}_loading") if options[:url][:id]
        options_add_confirm(html_options) if options.delete(:safe)
        link_to_remote(content, options, html_options)
      end
      
      def safe_link_to(content, options = {}, html_options = {})
        options_add_confirm(html_options)
        link_to(content, options, html_options)
      end

      # options for url are
      #   * <tt>:replace</tt> true or string
      #   * <tt>:append</tt> true or string
      #   * <tt>:on_complete</tt>
      def open_action_link(content, url, options = {})
        html_options = action_extract_html_options(options)
        action_add_loading(options)
        create_action_link(public_id(url), content, options.merge(:url => url), html_options)
      end

      def close_action_link(content, url = {}, options = {})
        html_options = action_extract_html_options(options)
        action_add_loading(options)
        
        if action_id = url.delete(:action_id) || controller.ajax_crud_options[:action_id]
          url[:ajax_crud_action_id] = action_id
        else
          url[:close] = url.delete(:action) || params[:action]
          url[:id] ||= (controller.model_object.id rescue nil)
        end
        url[:action] = 'close'
        
        link_to_remote(content, options.merge(:url => url), html_options)
      end

      def form_for_action(url = {}, options = {}, &block)
        action_add_loading(options)
        
        options[:before] = disable_form(public_id(url) + '_form')
        options[:html] ||= {}
        options[:html][:id] = "#{public_id(url)}_form"
        options[:builder] ||= Ardes::AjaxCrud::FormBuilder
        
        object_name = options.delete(:object_name) || controller.model_sym
        object = options.delete(:object) || controller.model_object

        url[:id] ||= (controller.model_object.id rescue nil)
        
        form_remote_for(object_name, object, options.merge(:url => url), &block)
      end

      # renders the inner part of the view action as if it had been rendered with a
      # replace 
      def render_panel_action(model)
        <<-end_render
          <div id="#{public_id(:id => model.id, :action => params[:panel_action])}" class="action">
            #{render :partial => params[:panel_action], :locals => {:model => model}}
          </div>
        end_render
      end
      
      def public_id(url = {})
        return url[:action_id] if url[:action_id]
        if url[:controller] && url[:controller] != controller.controller_name
          controller_class = "#{url[:controller]}_controller".classify.constantize
          controller_class.public_id(url)
        else
          controller.public_id(url)
        end
      end
      
    protected
      def action_add_loading(options)
        options_add_loading(options, "#{public_id}_loading")
        options_add_loading(options, "#{public_id(:id => (controller.model_object.attributes['id'] rescue nil))}_loading")
      end
    
      def action_extract_html_options(options)
        html_options = options.delete(:html) || {}
        html_options[:class] ||= 'action'
        html_options
      end
    end
  end
end