require File.join(File.dirname(__FILE__), '../spec_helper')
require File.join(File.dirname(__FILE__), '../fixtures/props')

ActiveRecord::Migration.suppress_messages { require File.join(File.dirname(__FILE__), '../fixtures/props_schema') }

context "An ActiveRecord::Singleton::Properties class" do
  include ActiveRecordSingletonSpecHelper
  
  setup { reset_singleton Props }
  
  specify "should provide content_column_names (and cache it)" do
    Props.content_column_names.should == ["foo_name", "rating"]
    Props.instance_variable_get("@content_column_names").should == ["foo_name", "rating"]
  end
  
  specify "should respond to column accessor methods" do
    [:foo_name, :rating].each do |column|
      Props.should_respond_to column
      Props.should_respond_to "#{column}="
      Props.should_respond_to "#{column}?"
    end
  end
  
  specify "should pass column getter to the instance" do
    Props.instance.should_receive(:read_property).with("foo_name").and_return(nil)
    Props.foo_name.should == nil
  end
  
  specify "should pass column boolean (?) to the instance" do
    Props.instance.should_receive(:read_property).with("foo_name").and_return(nil)
    Props.foo_name?.should == false
  end

  specify "should pass column setter to the instance" do
    Props.instance.should_receive(:write_property).with("foo_name", "fred").and_return("fred")
    Props.foo_name = "fred"
  end

  specify "should raise MethindMissing on a non-column accessor" do
    lambda{Proc.foo_bar}.should_raise NoMethodError
  end
  
  specify "should read property from the row and reload instance on property read" do
    Props.instance.update_attributes :foo_name => "fred"
    Props.instance.foo_name = "wilma" # <= without save
    Props.foo_name.should == "fred"
    Props.instance.foo_name.should == "fred"
  end
  
  specify "should write property to the row and reload instance on property write" do
    Props.foo_name = "wilma"
    Props.connection.select_value("SELECT foo_name FROM #{Props.table_name}").should == "wilma"
  end
end