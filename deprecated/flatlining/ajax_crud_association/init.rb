require 'ardes/ajax_crud_association'
ActionController::Base.class_eval { extend Ardes::AjaxCrudAssociation::Controller }