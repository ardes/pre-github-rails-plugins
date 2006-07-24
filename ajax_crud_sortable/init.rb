require 'ardes/ajax_crud_sortable'
ActionController::Base.class_eval { extend Ardes::AjaxCrudSortable::Controller }