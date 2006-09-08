require 'ardes/ajax_crud_has_one'
ActionController::Base.class_eval { extend Ardes::AjaxCrudHasOne::Controller }