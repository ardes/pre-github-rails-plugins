require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

# Note: because it's hard to completely reset the object space, these specs are brittle, and
# should be run in order.

describe 'Animal (class with has_types :pony)' do
  it 'should load subclasses on #new' do
    defined?(Animal).should == nil
    defined?(Pony).should == nil
    Animal.new
    Animal.send(:subclasses).collect(&:name).should == ['Pony']
  end
    
  it '#descends_from_active_record? should work' do
    Animal.descends_from_active_record?.should == true
    Pony.descends_from_active_record?.should == false
  end
end

if defined?(RAILS_GEM_VERSION) && RAILS_GEM_VERSION =~ /^1\.2/
  describe 'has_types (Rails 1.2.x)' do
    it 'should load subclasses when any descendent loaded, and have correct SQL on #find' do
      defined?(PortableDwelling).should == nil
      defined?(Dwelling).should == nil
      PortableDwelling.connection.should_receive(:select).with(
        "SELECT * FROM dwellings WHERE ( (dwellings.`type` = 'PortableDwelling' OR dwellings.`type` = 'Caravan' ) ) ",
        "PortableDwelling Load").and_return([])
      PortableDwelling.find(:all)
      Dwelling.send(:subclasses).collect(&:name).sort.should == ['Caravan', 'FixedDwelling', 'House', 'PortableDwelling']
    end
  end
else
  describe 'has_types' do
    it 'should load subclasses when any descendent loaded, and have correct SQL on #find' do
      defined?(PortableDwelling).should == nil
      defined?(Dwelling).should == nil
      PortableDwelling.connection.should_receive(:select).with(
        "SELECT * FROM `dwellings`   WHERE ( (`dwellings`.`type` = 'PortableDwelling' OR `dwellings`.`type` = 'Caravan' ) ) ",
        "PortableDwelling Load").and_return([])
      PortableDwelling.find(:all)
      Dwelling.send(:subclasses).collect(&:name).sort.should == ['Caravan', 'FixedDwelling', 'House', 'PortableDwelling']
    end
  end
end
  
describe "class Mansion < FixedDwelling; end (where :mansion is not in Dwelling.has_types)" do
  it 'should raise NameError' do
    lambda{ class Mansion < FixedDwelling; end }.should raise_error(NameError, "Mansion is not declared in Dwelling. Add has_types :mansion to Dwelling class definition")
  end
end

describe "class Pony < Animal; has_types :my_little; end" do
  it 'should raise error (can only specify has_types on STI base class)' do
    lambda{ class Pony < Animal; has_types :my_little; end }.should raise_error(RuntimeError, 'can only specify has_types on an STI base class')
  end
end

describe "class Dwelling (with :type_factory => true)" do
  it 'should return a FixedDwelling with new(:type => :fixed_dwelling)' do
    Dwelling.new(:type => :fixed_dwelling).class.should == FixedDwelling
  end
  
  it 'should return a FixedDwelling with new(:type => "FixedDwelling")' do
    Dwelling.new(:type => "FixedDwelling").class.should == FixedDwelling
  end
  
  it 'should raise argument error with new(:type => "Object")' do
    lambda { Dwelling.new(:type => 'Object') }.should raise_error(ArgumentError)
  end
  
  it 'should return Dwelling with new(:type => "Dwelling")' do
    Dwelling.new(:type => "Dwelling").class.should == Dwelling
  end
end

describe "class FixedDwelling < Dwelling" do
  it 'should return a House with new(:type => :house)' do
    FixedDwelling.new(:type => :house).class.should == House
  end
  
  it 'should return a House with new(:type => "House")' do
    FixedDwelling.new(:type => "House").class.should == House
  end
  
  it 'should raise argument error with new(:type => "Dwelling")' do
    lambda { FixedDwelling.new(:type => 'Dwelling') }.should raise_error(ArgumentError)
  end
  
  it 'should return FixedDwelling with new(:type => "FixedDwelling")' do
    FixedDwelling.new(:type => "FixedDwelling").class.should == FixedDwelling
  end
  
  it 'should be fine with FixedDwelling.new' do
    lambda { FixedDwelling.new }.should_not raise_error
  end
  
  it 'should not call type_class_names on any calls of load_type_dependencies' do
    FixedDwelling.should_not_receive(:type_class_names)
    FixedDwelling.load_type_dependencies
    FixedDwelling.descends_from_active_record? # calls load_type_dependencies
    FixedDwelling.send :type_condition # calls load_type_dependencies
  end
end