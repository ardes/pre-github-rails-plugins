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
  
  it 'should be cleaned up after outstanding dependencies loaded' do
    Animal.should_not respond_to(:descends_from_active_record_with_has_types?)
    Animal.should_not respond_to(:descends_from_active_record_without_has_types?)
    Animal.should respond_to?(:descends_from_active_record?)
  end
  
  it '#descends_from_active_record? should work' do
    Animal.descends_from_active_record?.should == true
    Pony.descends_from_active_record?.should == false
  end
end
  
describe 'has_types' do
  it 'should load outstanding dependencies when next active record loaded' do
    defined?(Product).should == nil
    defined?(Watch).should == nil
    Product
    Vehicle # this loads any outsanding dependencies
    Product.send(:subclasses).collect(&:name).should == ['Watch']
    Product.load_order.should == ['Product', 'Watch']
  end

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
  
describe "class Bling < Product; end (where Bling is not in Product.has_types)" do
  it 'should raise NameError' do
    lambda{ class Bling < Product; end }.should raise_error(NameError, "Bling is not declared in Product. Add has_types :bling to Product class definition")
  end
end

describe "class Truck < Vehicle; has_types :ute; end" do
  it 'should raise error (can only specify has_types on STI base class)' do
    lambda{ class Truck < Vehicle; has_types :ute; end }.should raise_error(RuntimeError, 'can only specify has_types on an STI base class')
  end
end