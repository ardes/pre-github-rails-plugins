if RAILS_ENV == 'test'
  require 'ardes/integration_referer'
  require 'action_controller/integration'
  ActionController::Integration::Session.send :include, Ardes::IntegrationReferer
end