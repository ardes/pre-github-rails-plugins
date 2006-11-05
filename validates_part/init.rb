require 'ardes/validations/validates_part'
ActiveRecord::Base.class_eval { include Ardes::Validations::ValidatesPart }

# include in ActiveRecord::Validations in case that is included elsewhere
ActiveRecord::Validations::ClassMethods.module_eval { include Ardes::Validations::ValidatesPart::ClassMethods }