require File.join(File.dirname(__FILE__), '../spec_helper')
require File.join(File.dirname(__FILE__), '../fixtures/props')
ActiveRecord::Migration.suppress_messages { require File.join(File.dirname(__FILE__), '../fixtures/props_schema') }  

context "An ActiveRecord::Singleton::Properties class" do
  include ActiveRecordSingletonSpecHelper
  
  setup { reset_singleton Props }
  
  specify "should provide (and cache) property_columns and property_column_names" do
    Props.property_column_names.should == ["foo_name", "rating", "ratings"]
    Props.instance_variable_get("@property_columns").should_not_be(nil)
    Props.instance_variable_get("@property_column_names").should_not_be(nil)
  end

  specify "should respond to property accessor methods" do
    [:foo_name, :rating, :ratings].each do |property|
      Props.should_respond_to property
      Props.should_respond_to "#{property}="
      Props.should_respond_to "#{property}?"
    end
  end
  
  specify "should pass property getter to the instance" do
    Props.instance.should_receive(:read_property).with("foo_name", {}).and_return(nil)
    Props.foo_name.should == nil
  end
  
  specify "should pass property question (?) to the instance" do
    Props.instance.should_receive(:read_property).with("foo_name", {}).and_return(nil)
    Props.foo_name?.should == false
  end

  specify "should pass property setter to the instance" do
    Props.instance.should_receive(:write_property).with("foo_name", "fred").and_return("fred")
    Props.foo_name = "fred"
  end

  specify "should raise NoMethodError on a non-property accessor" do
    lambda{Props.foo_bar}.should_raise NoMethodError
    lambda{Props.id = 9}.should_raise NoMethodError
  end
  
  specify "should read property from the row on property read" do
    Props.instance.update_attributes :foo_name => "fred"
    Props.instance.foo_name = "wilma" # <= without save
    Props.foo_name.should == "fred"
    Props.instance.foo_name.should == "fred"
  end
  
  specify "should write property to the row and on property write" do
    Props.foo_name = "wilma"
    Props.connection.select_value("SELECT foo_name FROM #{Props.table_name}").should == "wilma"
  end
  
  specify "should read property with pessimistic lock with :lock => true" do
    Props.rating = 0
    Props.ratings = ''
    config = ActiveRecord::Base.remove_connection
    pids = (1..5).to_a.collect { fork_with_new_connection(config) { increment_rating_and_append_to_ratings } }
    ActiveRecord::Base.establish_connection(config)
    pids.each {|pid| Process.waitpid pid}
    Props.ratings.should == '12345'
  end
  
  # For testing concurrency issues
  # this operation should be atomic, and also block any reading of the ratings until it
  # is done.  This will ensure that 5 successive calls always results in ratings being a 
  # string equal to '12345', no matter in what temporal order the operations occur.
  def increment_rating_and_append_to_ratings
    Props.transaction do
      r = Props.rating(:lock => true)
      sleep 0.2 # sleep before updating the database
      Props.rating = r + 1
      Props.ratings = Props.ratings + Props.rating.to_s
    end
  end
end