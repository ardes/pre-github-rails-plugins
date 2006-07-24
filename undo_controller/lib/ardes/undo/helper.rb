module Ardes
  module Undo
    module Helper
      def undoable_select_options
        undo_manager_select_options_for :undo
      end

      def redoable_select_options
        undo_manager_select_options_for :redo
      end

      def undo_manager_select_options_for(op)
        operations = (op == :undo ? controller.undoables : controller.redoables)
        if operations.size == 0
          "<option value=\"\">nothing to #{op}</option>"
        else
          operations.inject('') do |options, op|
            join = 'and ' unless options.size == 0
            options += "<option value=\"#{op.id}\">#{join}#{op.description.capitalize}</option>"
          end
        end
      end

      def any_undoables?
        return controller.undoables.size > 0
      end

      def any_redoables?
        return controller.redoables.size > 0
      end
    end
  end
end