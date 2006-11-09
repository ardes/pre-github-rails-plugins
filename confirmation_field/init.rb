# Moves the logic of dealing with confirmation fields into the view where it belongs.
# 
# A confirmation field is a virtual attribute that is used with
# 
#   validates_confirmation_of :email
# 
# :email_confirmation being the virtual attribute in the above example.
# 
# There's a small but annoying view logic issue with this, when you are presenting an update view of a model with a confirmation attribute, the 
# confirmation field will initially be left blank.  When the form is submitted, the above validation will fail, unless the user types in the confirmation field - very annoying for when you're only updating your phone number for example.
# 
# This means that you have to write some view logic to deal with this (a worse idea would be to change the *model* to deal with this view issue).
# 
# With this plugin you can do this in your views:
# 
#   <%= text_field :customer, :email %>
#   <%= confirmation_text_field :customer, :email %>
#
#   <%= password_field :customer, :pass %>
#   <%= confirmation_password_field :customer, :pass %>
#   
# or
# 
#   <% form_for :customer, @customer do |f| %>  
#     <%= f.text_field :email %>
#     <%= f.confirmation_text_field :email %>
#   <% end %>
#   
# The logic of this helper is as follows (example :email):
# * if there's an :email_confirmation non-nil value set on the model use that
# * otherwise use the value of :email
#   
# See the tests for more details.
# 
# ian.w.white@ardes.com

module ActionView::Helpers::FormHelper
  def confirmation_text_field(object_name, method, options = {})
    value = preload_confirmation_value(object_name, method)
    options[:value] = value unless value.nil?
    ::ActionView::Helpers::InstanceTag.new(object_name, "#{method}_confirmation".to_sym, self, nil, options.delete(:object)).to_input_field_tag("text", options)
  end

  def confirmation_password_field(object_name, method, options = {})
    value = preload_confirmation_value(object_name, method)
    options[:value] = value unless value.nil?
    ::ActionView::Helpers::InstanceTag.new(object_name, "#{method}_confirmation".to_sym, self, nil, options.delete(:object)).to_input_field_tag("password", options)
  end

private
  # if 'attr_confirmation' is nil, then return the value of 'attr'
  def preload_confirmation_value(object_name, method)
    object = instance_variable_get "@#{object_name}"
    if nil == (object.respond_to?("#{method}_confirmation_before_type_cast") ? object.send("#{method}_confirmation_before_type_cast") : object.send("#{method}_confirmation"))
      object.respond_to?("#{method}_before_type_cast") ? object.send("#{method}_before_type_cast") : object.send(method)
    else
      nil
    end
  end
end

class ActionView::Helpers::FormBuilder
  self.field_helpers += ['confirmation_text_field', 'confirmation_password_field']
  
  def confirmation_text_field(method, options = {})
    @template.send(:confirmation_text_field, @object_name, method, options.merge(:object => @object))
  end

  def confirmation_password_field(method, options = {})
    @template.send(:confirmation_password_field, @object_name, method, options.merge(:object => @object))
  end
end
