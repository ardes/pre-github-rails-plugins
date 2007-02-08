ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

# Even if you're using RSpec, RSpec on Rails is reusing some of the
# Rails-specific extensions for fixtures and stubbed requests, response
# and other things (via RSpec's inherit mechanism). These extensions are 
# tightly coupled to Test::Unit in Rails, which is why you're seeing it here.
module Spec
  module Rails
    class EvalContext < Test::Unit::TestCase
      cattr_accessor :fixture_path, :use_transactional_fixtures, :use_instantiated_fixtures
      self.use_transactional_fixtures = true
      self.use_instantiated_fixtures  = false
      self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')

      # You can set up your global fixtures here, or you
      # can do it in individual contexts
      #fixtures :table_a, :table_b
    end
  end
end

class TestController < ActionController::Base
  self.view_paths = [File.dirname(__FILE__) + '/fixtures/views']
end

class FirstController < TestController
  inherit_views
  
  def in_first; end
  def in_first_and_second; end
  def in_all; end
  def render_parent; end
end

class SecondController < TestController
  inherit_views 'first'

  def in_first; end
  def in_first_and_second; end
  def in_second; end
  def in_all; end
  def render_parent; end
end

class ThirdController < SecondController
  
  def in_third; end
  def render_parent; end
end
  