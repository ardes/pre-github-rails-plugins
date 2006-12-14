require File.join(File.dirname(__FILE__), '../spec_helper')
require File.join(File.dirname(__FILE__), '../fixtures/thing')
require File.join(File.dirname(__FILE__), '../fixtures/delayed_thing')

ActiveRecord::Migration.suppress_messages { require File.join(File.dirname(__FILE__), '../fixtures/thing_schema') }

context "An ActiveRecord::Singleton class (in general)" do
  include ActiveRecordSingletonSpecHelper

  setup { reset_singleton Thing }

  specify "should only create one instance" do
    Thing.instance.should_equal(Thing.instance)
  end
  
  specify "should not be able to create instances via new" do
    lambda { Thing.instance.new }.should_raise NoMethodError
  end

  specify "should not be able to destroy the instance" do
    lambda { Thing.instance.destroy }.should_raise NoMethodError
  end
end

context "An ActiveRecord::Singleton class (with an empty table)" do
  include ActiveRecordSingletonSpecHelper
  
  setup { reset_singleton Thing }

  specify "should insert a single row when getting the instance" do
    Thing.count.should == 0
    Thing.instance
    Thing.count.should == 1
  end
end

context "An ActiveRecord::Singleton class (with a row in its table)" do
  include ActiveRecordSingletonSpecHelper

  setup do
    reset_singleton Thing
    Thing.connection.execute "INSERT into #{Thing.table_name} SET name = 'fred'"
  end
  
  specify "should find the single row when getting the instance" do
    Thing.count.should == 1
    Thing.instance.name.should == 'fred'
  end

  specify "should only have one row in table after multiple saves" do
    3.times do
      Thing.instance.save
      Thing.count.should == 1
    end
  end
  
  specify "should get the instance via find" do
    Thing.find(:first).should_equal Thing.instance
  end
  
  specify "should get the instance in an array via find(:all)" do
    all = Thing.find(:all)
    all.length.should == 1
    all.first.should_equal Thing.instance
  end
  
  specify "should not find the instance when conditions don't match" do
    Thing.find(:first, :conditions => {:name => 'wilma'}).should_equal(nil)
  end

  specify "should return empty array with find(:all) when conditions don't match" do
    Thing.find(:all, :conditions => {:name => 'wilma'}).should == []
  end
  
  specify "should update the attributes of the instance when finding" do
    Thing.instance.name = "wilma" # not saved
    Thing.find(:first).name.should == "fred"
    Thing.instance.name.should == "fred"
  end
end

# These tests use a modified Singleton class with a delay between the select
# and insert for creating a new singleton row, see fixtures/delayed_thing.rb
context "An ActiveRecord::Singleton class (concurrent usage)" do
  include ActiveRecordSingletonSpecHelper
  
  setup { reset_singleton DelayedThing }
    
  specify "should instantiate the same object with multiple threads" do
    instances = []
    threads = (1..4).to_a.collect { Thread.new { instances << DelayedThing.instance } }
    threads.each {|thread| thread.join}
    instances.each {|i| i.should_equal DelayedThing.instance }
  end
  
  specify "should insert only one row with multiple threads" do
    threads = (1..4).to_a.collect { Thread.new { DelayedThing.instance } }
    threads.each {|thread| thread.join }
    DelayedThing.count.should == 1   
  end
  
  specify "should insert only one row with multiple processes" do
    config = ActiveRecord::Base.remove_connection
    pids = (1..4).to_a.collect { fork_with_new_connection(config) { DelayedThing.instance } }
    ActiveRecord::Base.establish_connection(config)
    pids.each {|pid| Process.waitpid pid}
    DelayedThing.count.should == 1
  end
end