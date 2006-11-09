require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/fixtures/confirmation_field_model'

context "Confirmation Field" do
  fixtures :confirmation_field_models
  
  class Controller < ActionController::Base# :nodoc:
    self.template_root = File.join(File.dirname(__FILE__), 'views')
  
    def edit
      @model = ConfirmationFieldModel.find(params[:id])
    end
    
    def update
      @model = ConfirmationFieldModel.find(params[:id])
      render :action => 'edit' unless @model.update_attributes(params[:model])
    end
    
    def rescue_action(exception); super(exception); raise exception; end
  end

  def setup
    @controller = Controller.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @model = ConfirmationFieldModel.find :first
  end
  
  def assert_input_tag_in_div(div_id, input_attributes)
    assert_tag :ancestor => {:attributes => {:id => div_id}},
      :tag => 'input',
      :attributes => input_attributes
  end
  
  specify "should populate confirmation fields with field values on fresh model" do
    get :edit, :id => @model.id
    ['old_style', 'block_style'].each do |div_id|
      assert_input_tag_in_div div_id, :name => 'model[email_confirmation]', :value => @model.email, :type => 'text'
      assert_input_tag_in_div div_id, :name => 'model[password_confirmation]', :value => @model.password, :type => 'password'
    end
  end
  
  specify "should not populate confirmation fields with field values when confirmation fields have changed" do
    post :update, :id => @model.id, :model => {:email_confirmation => 'gulp', :password_confirmation => 'burp'}
    # update should fail, and render edit, the confirmation fields should be those above
    
    ['old_style', 'block_style'].each do |div_id|
      assert_input_tag_in_div div_id, :name => 'model[email_confirmation]', :value => 'gulp', :type => 'text'
      assert_input_tag_in_div div_id, :name => 'model[password_confirmation]', :value => 'burp', :type => 'password'
    end
  end
  
  specify "should not populate confirmation fields when with field values when fields have changed" do
    post :update, :id => @model.id, :model => {:email_confirmation => @model.email, :password_confirmation => @model.password, :email => 'gulp', :password => 'burp'}
    # update should fail, and render edit, the confirmation fields should be those above
    
    ['old_style', 'block_style'].each do |div_id|
      assert_input_tag_in_div div_id, :name => 'model[email_confirmation]', :value => @model.email, :type => 'text'
      assert_input_tag_in_div div_id, :name => 'model[password_confirmation]', :value => @model.password, :type => 'password'
    end
  end
end