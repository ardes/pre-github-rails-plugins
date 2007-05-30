require 'ardes/view_mapping'
ActionController::Base.class_eval { extend Ardes::ActionController::ViewMapping }
ActionView::Base.class_eval { include Ardes::ActionView::ViewMapping }