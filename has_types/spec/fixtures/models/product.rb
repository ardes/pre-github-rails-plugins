class Product < ActiveRecord::Base
  has_types :watch
  
  cattr_accessor :load_order
  self.load_order ||= []
  self.load_order << 'Product'
end