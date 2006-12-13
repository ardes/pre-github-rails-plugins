require 'active_record/singleton/properties'

class Props < ActiveRecord::Base
  include ActiveRecord::Singleton::Properties
  self.table_name = 'props'
end
