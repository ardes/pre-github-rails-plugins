require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/fixtures/ajax_crud_model'
require 'ardes/test/ajax_crud'

class AjaxCrudModelController < ActionController::Base
  ajax_crud :ajax_crud_model
  self.template_root = File.dirname(__FILE__) + '/views'
  
  def default_params
    {:foo => 'bar'}
  end
end

class AjaxCrudTest < Test::Unit::TestCase
  fixtures :ajax_crud_models
  
  test_ajax_crud AjaxCrudModelController, :ajax_crud_model, :first,
    :valid => {:name => 'changed'},
    :invalid => {:name => ''}
  
  def test_model_list
    list = [ajax_crud_models(:first), ajax_crud_models(:second), ajax_crud_models(:third)]
    assert_equal list, @controller.model_list
    assert_equal list, @controller.instance_eval { @ajax_crud_models }
    
    AjaxCrudModel.delete_all
    assert_equal list, @controller.model_list(reload = false)
    assert_equal [],   @controller.model_list(reload = true)
    assert_equal [],   @controller.instance_eval { @ajax_crud_models }
  end
  
  def test_find_or_new_model
    obj = @controller.instance_eval { find_or_new_model }
    assert_equal obj, @controller.instance_eval { @ajax_crud_model }
    
    assert_equal ajax_crud_models(:first), obj = @controller.instance_eval { find_or_new_model(1) }
    assert_equal obj, @controller.instance_eval { @ajax_crud_model }
  end
  
  def test_model_desc
    assert_equal 'ajax crud model: 1', @controller.model_desc(ajax_crud_models(:first))
    @controller.instance_eval { find_model(3) }
    assert_equal 'ajax crud model: 3', @controller.model_desc
  end
  
  def test_class_sanitize_url
    assert_equal({:action => 'fred', :params => {:id => 666, :thing => 'here', :b => 'c'}},
      @controller.class.sanitize_url(:id => 666, :thing => 'here', :action => 'fred', :params => {:b => 'c'}))
  end
  
  def test_internal_url
    assert_equal({:action => 'fred', :params => {:foo => 'bar', :id => 666}}, @controller.internal_url(:action => 'fred', :id => 666))
  end
    
  def test_class_public_id_with_no_args
    assert_equal 'ajax_crud_model', AjaxCrudModelController.public_id
  end
  
  def test_class_public_id_with_action
    assert_equal 'ajax_crud_model_action', AjaxCrudModelController.public_id(:action => 'action')
  end
  
  def test_class_public_id_with_id
    assert_equal 'ajax_crud_model_666', AjaxCrudModelController.public_id(:id => 666)
    assert_equal 'ajax_crud_model_666', AjaxCrudModelController.public_id(:params => {:id => 666})
  end
  
  def test_class_public_id_with_action_and_id
    assert_equal 'ajax_crud_model_666_action', AjaxCrudModelController.public_id(:id => 666, :action => 'action')
    assert_equal 'ajax_crud_model_666_action', AjaxCrudModelController.public_id(:params => {:id => 666}, :action => 'action')
  end  
end

