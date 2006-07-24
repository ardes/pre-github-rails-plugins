require 'ardes/ajax_crud_belongs_to'
ActionController::Base.class_eval { extend Ardes::AjaxCrudBelongsTo::Controller }