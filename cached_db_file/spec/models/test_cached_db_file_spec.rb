require File.dirname(__FILE__) + '/../spec_helper'

context "A TestCachedDbFile timestamped_filename" do
  setup do
    @cache = TestCachedDbFile.new
  end
  
  specify "should be 'filename_timestamp' for filename WITHOUT extension" do
    @cache.attributes = {:filename => 'foo', :updated_at => Time.mktime(2000,1,2,3,4,5)}
    @cache.send(:timestamped_filename).should == 'foo_20000102030405'
  end
  
  specify "should be 'filename_timestamp.ext' for filename WITH extension" do
    @cache.attributes = {:filename => 'foo.jpg', :updated_at => Time.mktime(2000,1,2,3,4,5)}
    @cache.send(:timestamped_filename).should == 'foo_20000102030405.jpg'
  end

  specify "should be 'filename' when there is no timestamp (updated_on or updated_at)" do
    @cache.attributes = {:filename => 'foo', :updated_at => nil}
    @cache.send(:timestamped_filename).should == 'foo'
  end
end


context "An TestCachedDbFile (in general)" do
  fixtures :db_files, :test_cached_db_files
 
  setup do
    @cache = test_cached_db_files(:first)
  end

  specify 'should have full_filename == #{cached_db_file_root}/test_cached_db_files/0/0/1/first_#{timestamp}.txt' do
    @cache.full_filename.should == "#{@cache.cached_db_file_root}/test_cached_db_files/0/0/1/first_20070101100000.txt"
  end
  
  specify 'should have public_filename == /test_cached_db_files/0/0/1/first_#{timestamp}.txt' do
    @cache.public_filename.should == "/test_cached_db_files/0/0/1/first_20070101100000.txt"
  end
end

context "A new TestCachedDbFile" do
  fixtures :db_files, :test_cached_db_files
  
  setup do
    @cache = TestCachedDbFile.new :filename => 'foo.txt'
  end
  
  specify "should be invalid without a filename" do
    @cache.filename = nil
    @cache.should_not be_valid
  end
  
  specify "should be valid with filename" do
    @cache.should be_valid
  end
  
  specify "should build db_file on demand" do
    @cache.instance_variable_get('@db_file').should == nil
    @cache.db_file.should_not == nil
  end
  
  specify "should raise error when accessing cached_filename" do
    lambda{ @cache.cached_filename }.should raise_error
  end
  
  specify "should delegate data= to db_file" do
    @cache.data = 'foo'
    @cache.db_file.data.should == 'foo'
  end
  
  specify "should delegate data to db_file" do
    @cache.db_file.data = 'foo'
    @cache.data.should == 'foo'
  end
  
  specify "should create db_file on save" do
    @cache.save
    DbFile.find(@cache.db_file_id).should == @cache.db_file
  end
end

context "An existing TestCachedDbFile WITHOUT a cached file present" do
  fixtures :db_files, :test_cached_db_files
 
  setup do
    TestCachedDbFile.remove_cache
    @cache = test_cached_db_files(:first)
  end
  
  specify "should access db_file when full_filename called" do
    @cache.should_receive(:db_file).once.and_return(db_files(:first))
    @cache.full_filename
  end
  
  specify "should create cached file when full_filename called" do
    File.exist?(@cache.full_filename).should == true
  end

  specify "should create cached file when public_filename called" do
    @cache.public_filename
    File.exist?(@cache.cached_filename).should == true
  end
  
  specify "should create the cached file with db_file.data" do
    File.read(@cache.full_filename).should == @cache.data
  end
end

context "An existing TestCachedDbFile WITH a cached file present" do
  fixtures :db_files, :test_cached_db_files
 
  setup do
    TestCachedDbFile.remove_cache
    TestCachedDbFile.find(1).send :write_cached_file
    @cache = test_cached_db_files(:first)
  end
  
  specify "should not access db_file when full_filename called" do
    @cache.should_not_receive(:db_file)
    @cache.full_filename
  end
  
  specify "should remove cached file on destroy" do
    @cache.destroy
    File.exist?(@cache.cached_filename).should == false
  end
  
  specify "should remove cached file, and empty enclosing dirs, on update" do
    @cache.update_attributes :data => 'FOOOO'
    File.exist?(@cache.cached_filename).should == false
  end
  
  specify "should destroy db_file on destroy" do
    @cache.destroy
    lambda{ DbFile.find(@cache.db_file_id) }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  specify "should remove empty enclosing id dirs on remove_cached_file" do
    @cache.send :remove_cached_file
    path = @cache.cached_filename
    # path is /0/0/1
    File.exist?(path = File.dirname(path)).should == false  
    File.exist?(path = File.dirname(path)).should == false
    File.exist?(path = File.dirname(path)).should == false
    File.exist?(path = File.dirname(path)).should == true
  end
  
  specify "should NOT remove NON-empty enclosing id dirs on remove_cached_file" do
    TestCachedDbFile.create(:filename => 'foobar.txt').full_filename
    @cache.send :remove_cached_file
    path = @cache.cached_filename
    File.exist?(path = File.dirname(path)).should == false  
    File.exist?(path = File.dirname(path)).should == true
  end
  
  specify "should update the cached file when data updated" do
    @cache.data = 'FOOOO'
    @cache.save 
    File.read(@cache.full_filename).should == 'FOOOO'
  end
  
  specify "should re-cache when timestamp (updated_on, updated_at) has changed" do
    @cache.should_receive(:db_file).once.and_return(db_files(:first))
    TestCachedDbFile.connection.update("UPDATE test_cached_db_files SET updated_at='2008-02-02 12:00:00'")
    @cache.reload.full_filename
  end
end