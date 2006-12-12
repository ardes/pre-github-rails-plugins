require 'active_record/singleton'

class Thing < ActiveRecord::Base
  include ActiveRecord::Singleton
end
