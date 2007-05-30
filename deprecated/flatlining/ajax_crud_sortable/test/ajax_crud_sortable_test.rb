require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'fixtures/ajax_crud_sortable_model'))
require 'ardes/test/ajax_crud'

class AjaxCrudSortableModelController < ActionController::Base
  ajax_crud :ajax_crud_sortable_model
  ajax_crud_sortable
  self.template_root = File.dirname(__FILE__) + '/views'
end

class AjaxCrudSortableTest < Test::Unit::TestCase
  fixtures :ajax_crud_sortable_models
  
  test_ajax_crud AjaxCrudSortableModelController, :ajax_crud_sortable_model, :first,
    :valid => {:name => 'changed'},
    :invalid => {:name => ''}
    
  def test_sortable_on
    xhr :get, :sortable, :sort => true
    assert_response :success
    assert_equal assigns["sorting"], true
    assert_template "ajax_crud_sortable/sortable"

    assert_rjs :replace_html, 'ajax_crud_sortable_model_list'
    assert_rjs :replace_html, 'ajax_crud_sortable_model_nav_links', /Drag the/
  end
  
  def test_sortable_off
    xhr :get, :sortable, :sort => false
    assert_response :success
    assert_equal assigns["sorting"], false
    assert_template "ajax_crud_sortable/sortable"

    assert_rjs :replace_html, 'ajax_crud_sortable_model_list'
    assert_rjs :replace_html, 'ajax_crud_sortable_model_nav_links'
  end
  
  def test_sort
    xhr :post, :sort, :ajax_crud_sortable_model_sortable_list => [3, 1, 2]
    assert_response :success
    assert_equal [AjaxCrudSortableModel.find(3), AjaxCrudSortableModel.find(1), AjaxCrudSortableModel.find(2)], @controller.model_list
  end
end
