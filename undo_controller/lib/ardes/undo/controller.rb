require 'ardes/undo/helper'

module Ardes
  module Undo
    module Controller
      def self.included(base)
        base.class_eval do
          cattr_accessor :undo_operation_find_options
          self.undo_operation_find_options = {}
          
          include Actions
          include InstanceMethods
          
          helper Ardes::Undo::Helper
          
          before_filter :load_undo_manager
        end
      end
      
      module Actions
        def undo
          @undo_manager.operations.find(params[:to].to_i).undo
          redirect_to :back
        end
        
        def redo
          @undo_manager.operations.find(params[:to].to_i).redo
          redirect_to :back
        end
      end
      
      module InstanceMethods
        def self.included(base)
          methods = self.public_instance_methods
          base.class_eval { hide_action(*methods) }
        end
        
        def undoables
          @undoables ||= @undo_manager.undoables(:all, self.undo_operation_find_options)
        end

        def redoables
          @redoables ||= @undo_manager.redoables(:all, self.undo_operation_find_options)
        end
        
      private
        def load_undo_manager
          @undo_manager = Ardes::UndoManager.for(params[:scope].to_sym)
        end
      end
    end
  end
end
