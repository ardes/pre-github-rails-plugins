require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe SecondController, " < TestController; inherit_views 'first'" do
  it { SecondController.should be_inherit_views }

  it "should have inherit view paths == ['second', 'first']" do
    SecondController.inherit_view_paths.should == ['second', 'first']
  end
end

describe SecondController do
  integrate_views
  
  it { @controller.should be_inherit_views }

  it "should have inherit view paths == ['second', 'first']" do
    @controller.inherit_view_paths.should == ['second', 'first']
  end
  
  it "GET :in_first should render first/in_first" do
    get :in_first
    response.body.should == 'first:in_first'
  end
  
  it "GET :in_first_and_second should render second/in_first_and_second" do
    get :in_first_and_second
    response.body.should == 'second:in_first_and_second'
  end
  
  it "GET :in_second should render second/in_second" do
    get :in_second
    response.body.should == 'second:in_second'
  end

  it "GET :in_all should render second/in_all" do
    get :in_all
    response.body.should == 'second:in_all'
  end

  it "GET :render_parent should render first/render_parent inside second/render_parent" do
    get :render_parent
    response.body.should == "first:render_parent\nsecond:render_parent"
  end
  
  it "GET :bad_render_parent should raise ActionView::TemplateError as there is no parent to render" do
    lambda { get :bad_render_parent }.should raise_error(ActionView::TemplateError, "no parent for second/bad_render_parent found")
  end
  
  it "GET :partial should render second/partial & second/_partial" do
    get :partial
    response.body.should == "second:partial\nsecond:_partial"
  end
  
  it "GET :partial2 should render second/partial2 & second/_partial2" do
    get :partial2
    response.body.should == "second:partial2\nsecond:_partial2"
  end
end