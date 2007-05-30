ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

Spec::Runner.configure do |config|
end