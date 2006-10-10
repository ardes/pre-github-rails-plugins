require 'ssl_requirement_if'
ActionController::Base.class_eval { include SslRequirementIf }