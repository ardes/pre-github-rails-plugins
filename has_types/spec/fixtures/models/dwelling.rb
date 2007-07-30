class Dwelling < ActiveRecord::Base
  has_types :portable_dwelling, :caravan, :fixed_dwelling, :house, :type_factory => true
end