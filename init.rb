require 'ardes/active_record/asym_crypt'
ActiveRecord::Base.class_eval { extend Ardes::ActiveRecord::AsymCrypt }