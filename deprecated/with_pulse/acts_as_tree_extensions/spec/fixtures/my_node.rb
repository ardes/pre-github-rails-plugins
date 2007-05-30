class MyNode < ActiveRecord::Base
  acts_as_tree
  
  def inspect
    "{##{object_id} id:#{id} '#{name}'}"
  end
end