require File.dirname(__FILE__) + '/test_helper'

class TestController < ActionController::Base
  ensure_canonical_host 'ardes.com'
  ensure_canonical_host 'milliways.com', 'svn.milliways.com'
  ensure_canonical_host /think/, 'www.think.com'
  
  def rescue_action(e); super(e); raise(e); end
  
  def foo
    render :text => '<foo />'
  end
  
end

class EnsureCanonicalHostTest < Test::Unit::TestCase

  def setup
    @controller = TestController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_redirect_ardes_com_to_www_ardes_com
    @request.host = 'ardes.com'
    get :foo
    assert_redirected_to "http://www.ardes.com#{@controller.url_for(:action => 'foo', :only_path => true)}"
  end
  
  def test_redirect_blah_ardes_com_to_www_ardes_com
    @request.host = 'blah.ardes.com'
    get :foo
    assert_redirected_to "http://www.ardes.com#{@controller.url_for(:action => 'foo', :only_path => true)}"
  end
  
  def test_no_redirect_with_www_ardes_com
    @request.host = 'www.ardes.com'
    get :foo
    assert_response :success
    assert_tag :tag => 'foo'
  end
  
  def test_milliways_redirect
    @request.host = 'www.milliways.com'
    get :foo
    assert_redirected_to "http://svn.milliways.com#{@controller.url_for(:action => 'foo', :only_path => true)}"
  end
  
  def test_no_redirect_on_svn_milliways_com
    @request.host = 'svn.milliways.com'
    get :foo
    assert_response :success
    assert_tag :tag => 'foo'
  end
  
  def test_think_redirect
    @request.host = 'bling.thinker.com'
    get :foo
    assert_redirected_to "http://www.think.com#{@controller.url_for(:action => 'foo', :only_path => true)}"
  end
end
