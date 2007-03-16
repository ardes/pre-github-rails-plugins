# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

# Even if you're using RSpec, RSpec on Rails is reusing some of the
# Rails-specific extensions for fixtures and stubbed requests, response
# and other things (via RSpec's inherit mechanism). These extensions are 
# tightly coupled to Test::Unit in Rails, which is why you're seeing it here.
module Spec
  module Rails
    module Runner
      class EvalContext < Test::Unit::TestCase
        self.use_transactional_fixtures = true
        self.use_instantiated_fixtures  = false
        self.fixture_path = File.expand_path(File.join(File.dirname(__FILE__), '/fixtures'))

        # You can set up your global fixtures here, or you
        # can do it in individual contexts using "fixtures :table_a, table_b".
        #
        #self.global_fixtures = :table_a, :table_b
      end
    end
  end
end

### APP SETUP

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :db_files, :force => true do |t|
      t.column "data", :binary
    end

    create_table :test_cached_db_files, :force => true do |t|
      t.column "db_file_id", :integer
      t.column "filename", :string
    end
  end
end

require 'ardes/cached_db_file'
class TestCachedDbFile < ActiveRecord::Base
  include Ardes::CachedDbFile
  self.cached_db_file_root = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures/public'))
  
  class<<self
    def remove_cache
      FileUtils.rm_rf self.cached_db_file_root
    end
  end
end