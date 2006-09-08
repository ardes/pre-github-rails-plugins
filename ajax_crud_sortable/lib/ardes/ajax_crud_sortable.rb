module Ardes
  module AjaxCrudSortable
    module Controller
      def ajax_crud_sortable(options = {})
        raise 'ajax_crud_sortable requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
        include Actions
        find_options = self.model_find_options.dup
        find_options[:order] = options[:order] if options[:order]
        find_options[:order] ||= "#{model_sym.to_s.tableize}.position"
        self.model_find_options = find_options.freeze
        
        inherit_views 'ajax_crud_sortable', :at => 'ajax_crud'
        view_mapping 'ajax_crud_sortable' => File.expand_path(File.join(File.dirname(__FILE__), '../../views'))

      end

      module Actions
        def sortable
          @sorting = params[:sort]
          model_list
        end

        def sort
          self.model_class.transaction do
            params["#{public_id}_sortable_list".to_sym].each_with_index do |id, position|
              self.model_class.update(id, :position => position)
            end
          end
          render_nothing
        end
      end
    end
  end
end
