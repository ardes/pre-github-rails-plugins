require File.dirname(__FILE__) + '/test_helper'

module AssetsInViewsTestHelper
protected
  def assert_stylesheet_tag(source)
    assert_tag :tag => 'link', :attributes => {
      :href => url_for(:action => 'asset', :format => 'rcss', :source => source, :extension => 'css'),
      :media => 'screen', :rel => 'Stylesheet', :type => 'text/css' }
  end
  
  def assert_javascript_tag(source)
    assert_tag :tag => 'script', :attributes => {
      :src => url_for(:action => 'asset', :format => 'r_js', :source => source, :extension => 'js'),
      :type => 'text/javascript' }
  end
end

class ApplesController < ActionController::Base
  assets_in_views
  
  self.template_root = File.join(File.dirname(__FILE__), 'views')
  def rescue_action(exception); super(exception); raise exception; end
end

#
# Tests case where stylsheets and javascripst are in the apples/ directory
#
class AssetsInViewsTest < Test::Unit::TestCase
  include AssetsInViewsTestHelper
  
  def setup
    @controller = ApplesController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
    
  def test_render_rcss_asset
    get :asset, {:format => 'rcss', :source => 'stylesheet'}
    assert_response :success
    assert_equal '/* A stylesheet */', @response.body
    assert_equal 'text/css', @response.headers['Content-Type']
  end
  
  def test_render_r_js_asset
    get :asset, {:format => 'r_js', :source => 'javascript'}
    assert_response :success
    assert_equal '/* A javascript */', @response.body
    assert_equal 'text/javascript', @response.headers['Content-Type']
  end
  
  def test_render_default_asset
    get :asset, {:format => 'rhtml', :source => 'index'}
    assert_response :success
    assert_equal '<index />', @response.body
    assert_equal 'text/plain', @response.headers['Content-Type']
  end
  
  def test_default_asset_tags
    @controller.class.layout 'apples/layout_default'
    get :index
    assert_response :success
    assert_asset_tags
    assert :tag => 'index'
  end

  def test_file_name_asset_tags
    @controller.class.layout 'apples/layout_file_name'
    get :index
    assert_response :success
    assert_asset_tags
    assert :tag => 'index'
  end

  def test_file_name_no_ext_asset_tags
    @controller.class.layout 'apples/layout_file_name_no_ext'
    get :index
    assert_response :success
    assert_asset_tags
    assert :tag => 'index'
  end

private
  def assert_asset_tags
    assert_stylesheet_tag('stylesheet')
    assert_javascript_tag('javascript')
  end 
end


class OrangesController < ActionController::Base
  assets_in_views
  layout 'oranges/layout'
  
  self.template_root = File.join(File.dirname(__FILE__), 'views')
  def rescue_action(exception); super(exception); raise exception; end
end

#
# Tests case where assets are in subdirectories (like oranges/javascripts/)
#
class AssetsInViewsSubdirectoryTest < Test::Unit::TestCase
  include AssetsInViewsTestHelper

  def setup
    @controller = OrangesController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_index
    get :index
    assert_response :success
    assert_stylesheet_tag 'stylesheets/one'
    assert_stylesheet_tag 'stylesheets/two'
    assert_javascript_tag 'javascripts/one'
    assert_javascript_tag 'javascripts/two'
    assert :tag => 'index'
  end
  
  def test_render_stylesheet_one
    get :asset, {:format => 'rcss', :source => 'stylesheets/one'}
    assert_response :success
    assert_equal '/* stylesheet one */', @response.body
    assert_equal 'text/css', @response.headers['Content-Type']
  end
  
  def test_render_javascript_one
    get :asset, {:format => 'r_js', :source => 'javascripts/one'}
    assert_response :success
    assert_equal '/* javascript one */', @response.body
    assert_equal 'text/javascript', @response.headers['Content-Type']
  end
end

