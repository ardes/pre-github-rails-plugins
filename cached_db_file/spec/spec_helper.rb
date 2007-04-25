ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

require File.expand_path(File.join(File.dirname(__FILE__), "app.rb"))

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
end