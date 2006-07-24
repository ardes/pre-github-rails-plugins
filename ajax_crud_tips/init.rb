require 'ardes/ajax_crud_tips'
ActionController::Base.class_eval { extend Ardes::AjaxCrudTips::Controller }