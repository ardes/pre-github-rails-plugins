require 'ardes/assets_in_views'
ActionController::Base.class_eval { extend Ardes::ActionController::AssetsInViews }