require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require File.expand_path(File.join(File.dirname(__FILE__), 'scam'))

describe Scam, ' class (migration helpers)' do
  it '#drop_table should drop scams table' do
    Scam.connection.should_receive(:drop_table).with('scams')
    Scam.drop_table
  end
  
  it '#create_table should create scams table and indexes' do
    Scam.connection.should_receive(:create_table).with('scams', {})
    Scam.connection.should_receive(:add_index).any_number_of_times
    Scam.create_table
  end
end

describe Scam, '#to_content(:whatever) (without parsed_content[:whatever])' do
  before do
    @scam = Scam.new
  end
  
  it 'should call #parse_to_whatever' do
    @scam.should_receive(:parse_to_whatever).once.and_return('parsed')
    @scam.to_content(:whatever)
  end
  
  it 'should call parse_to(:whatever) if #parse_whatever is undefined' do
    @scam.should_receive(:parse_to).with(:whatever).once.and_return('parsed')
    @scam.to_content(:whatever)
  end

  it 'should store the results of parse_to(:whetever) in parsed_content[:whatever] and save record' do
    @scam.stub!(:parse_to).and_return('parsed')
    @scam.should_receive(:save).once
    @scam.to_content(:whatever)
    @scam.parsed_content[:whatever].should == 'parsed'
  end
end

describe Scam, '#to_content(:whatever) (with parsed_content[:whatever])' do
  before do
    @scam = Scam.new
    @scam.parsed_content[:whatever] = 'parsed'
  end

  it 'should return parsed_content[:whatever]' do
    @scam.to_content(:whatever).should == 'parsed'
  end
  
  it 'should not save record' do
    @scam.should_not_receive(:save)
    @scam.to_content(:whatever)
  end
end

describe Scam, '.new' do
  before { @scam = Scam.new }
  
  it_should_behave_like 'Scam'
  
  it 'should return {} for #parsed_content' do
    @scam.parsed_content.should == {}
  end
  
  it 'should return content.to_s with to_s' do
    @scam.content = 1
    @scam.to_s.should == '1'
  end
end