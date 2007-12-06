require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe ScopeSpecModel, " (in general)" do
  it "#with_published should call #with_scope with published scope options" do
    ScopeSpecModel.should_receive(:with_scope).with(ScopeSpecModel.named_scopes[:published])
    ScopeSpecModel.with_published {}
  end
  
  it "#find_published_by_id should call #with_published with block that calls #find_by_id" do
    ScopeSpecModel.should_receive(:with_published).and_yield
    ScopeSpecModel.should_receive(:find_by_id).with(1)
    ScopeSpecModel.find_published_by_id(1)
  end
    
  it "count_published should call #with_published with a block that calls :count" do
    ScopeSpecModel.should_receive(:with_published).and_yield
    ScopeSpecModel.should_receive(:count)
    ScopeSpecModel.count_published
  end
end

describe ScopeSpecModel, " (use case: 2 published, 1 unpublished record)" do
  before do
    @published1 = ScopeSpecModel.create! :published => true
    @published2 = ScopeSpecModel.create! :published => true
    @unpublished = ScopeSpecModel.create! :published => false
  end
  
  it "#count_published should == 2" do
    ScopeSpecModel.count_published.should == 2
  end
  
  it "#destroy_all_published should not destroy unpublished" do
    ScopeSpecModel.destroy_all_published
    ScopeSpecModel.find(:all).should == [@unpublished]
  end
  
  it "#find_published(:all) should find only published" do
    ScopeSpecModel.find_published(:all).should == [@published1, @published2]
  end

  it "#new_published should set published = true" do
    ScopeSpecModel.new_published.published.should == true
  end
end