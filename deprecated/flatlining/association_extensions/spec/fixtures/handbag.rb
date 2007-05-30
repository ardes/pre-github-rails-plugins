class Handle < ActiveRecord::Base
  belongs_to :container
end

class Thing < ActiveRecord::Base
  belongs_to :handbag
end 

class Handbag < ActiveRecord::Base
  has_one :handle
  has_many :things
  belongs_to :owner
  
  preload_self_in :things
  preload_self_in :handle, :as => :container
end

class Owner < ActiveRecord::Base
  has_many :handbags
  
  preload_self_in :handbags
end