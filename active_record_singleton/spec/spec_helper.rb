ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

config = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
ActiveRecord::Base.establish_connection(config['db'])

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


# Testing singleton classes is a bit tricky, because you probably want to
# reset the singleton between tests.  This can't really be done without violating
# Singleton's purpose in life.  The solution is to do the following:
#   
#   Singleton.send :__init__, TheSingletonClassInQuestion # <= a class
#
# So we add this as in reset_instance method to the singleton module when we're testing
require 'singleton'

class << Singleton
  def included_with_reset(klass)
    included_without_reset(klass)
    class <<klass
      def reset_instance
        Singleton.send :__init__, self
        self
      end
    end
  end
  alias_method :included_without_reset, :included
  alias_method :included, :included_with_reset
end

module ActiveRecordSingletonSpecHelper
  def reset_singleton(klass)
    klass.reset_instance
    klass.delete_all
  end
  
  def fork_with_new_connection(config, klass = ActiveRecord::Base)
    fork do
      begin
        klass.establish_connection(config)
        yield
      ensure
        klass.remove_connection
      end
    end
  end
end