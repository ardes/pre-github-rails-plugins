class ConfirmationFieldModel < ActiveRecord::Base# :nodoc:
  validates_confirmation_of :email
  validates_confirmation_of :password
end
