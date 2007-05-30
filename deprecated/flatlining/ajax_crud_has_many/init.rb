require 'ardes/ajax_crud_has_many'
ActionController::Base.class_eval { extend Ardes::AjaxCrudHasMany::Controller }