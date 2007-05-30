require 'active_record/singleton'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :things, :force => true do |t|
      t.column "name", :string
    end
  end
end

class Thing < ActiveRecord::Base
  include ActiveRecord::Singleton
end

# add a delay after the singleton attributes are read.  This will expose any
# concurrency issues as concurrrent processes will all (most) perform the read before an
# update or insert is performed
class DelayedThing < Thing
  class<<self
    def read_singleton_attributes_with_delay(options = {})
      read_singleton_attributes_without_delay(options)
    ensure
      sleep 0.2
    end
    alias_method_chain :read_singleton_attributes, :delay
  end 
end
