require File.dirname(__FILE__) + '/../../spec_helper'

describe "the BehaviourFactory" do
  it "should return a ModelBehaviour when given :rails_component_type => :model" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :rails_component_type => :model) {
    }.should be_an_instance_of(Spec::Rails::DSL::ModelBehaviour)
  end
  
  it "should return a ModelBehaviour when given :spec_path => '/blah/spec/models/'" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '/blah/spec/models/blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::ModelBehaviour)
  end
  
  it "should return a ModelBehaviour when given :spec_path => '\blah\spec\models\' (windows format)" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '\blah\spec\models\blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::ModelBehaviour)
  end
  
  it "should return a ViewBehaviour when given :rails_component_type => :model" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :rails_component_type => :view) {
    }.should be_an_instance_of(Spec::Rails::DSL::ViewBehaviour)
  end
  
  it "should return a ViewBehaviour when given :spec_path => '/blah/spec/views/'" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '/blah/spec/views/blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::ViewBehaviour)
  end
  
  it "should return a ModelBehaviour when given :spec_path => '\blah\spec\views\' (windows format)" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '\blah\spec\views\blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::ViewBehaviour)
  end
  
  it "should return a HelperBehaviour when given :rails_component_type => :helper" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :rails_component_type => :helper) {
    }.should be_an_instance_of(Spec::Rails::DSL::HelperBehaviour)
  end
  
  it "should return a HelperBehaviour when given :spec_path => '/blah/spec/helpers/'" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '/blah/spec/helpers/blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::HelperBehaviour)
  end
  
  it "should return a ModelBehaviour when given :spec_path => '\blah\spec\helpers\' (windows format)" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '\blah\spec\helpers\blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::HelperBehaviour)
  end
  
  it "should return a ControllerBehaviour when given :rails_component_type => :controller" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :rails_component_type => :controller) {
    }.should be_an_instance_of(Spec::Rails::DSL::ControllerBehaviour)
  end
  
  it "should return a ControllerBehaviour when given :spec_path => '/blah/spec/controllers/'" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '/blah/spec/controllers/blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::ControllerBehaviour)
  end
  
  it "should return a ModelBehaviour when given :spec_path => '\blah\spec\controllers\' (windows format)" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '\blah\spec\controllers\blah.rb') {
    }.should be_an_instance_of(Spec::Rails::DSL::ControllerBehaviour)
  end
  
  it "should favor the :rails_component_type over the :spec_path" do
    Spec::Rails::Runner::BehaviourFactory.create("name", :spec_path => '/blah/spec/models/blah.rb', :rails_component_type => :controller) {
    }.should be_an_instance_of(Spec::Rails::DSL::ControllerBehaviour)
  end
end
