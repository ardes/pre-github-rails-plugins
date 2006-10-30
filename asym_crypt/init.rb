require 'active_record/asym_crypt'
ActiveRecord::Base.class_eval { extend ActiveRecord::AsymCrypt }