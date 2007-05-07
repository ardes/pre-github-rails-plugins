require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

module CachedDbFileSpec
  describe "CachedDbFile#timestamped_filename" do
    before(:each) { @cache = CachedDbFile.new }
    
    it 'should return "#{filename}" when no timestamp (:updated_at, :updated_on) present' do
      @cache.filename = 'foo.ext'
      @cache.send(:timestamped_filename).should == 'foo.ext'
    end

    it 'should return "#{filename}_#{timestamp}" with timestamp (:updated_at, :updated_on) and when :filename has no extension' do
      @cache.filename = 'foo'
      @cache.updated_at = Time.mktime(2000,1,2,3,4,5)
      @cache.send(:timestamped_filename).should == "foo_20000102030405"
    end
    
    it 'should return "#{basename}_#{timestamp}.#{ext}" with timestamp (:updated_at, :updated_on) and when :filename has an extension' do
      @cache.filename = 'foo.ext'
      @cache.updated_at = Time.mktime(2000,1,2,3,4,5)
      @cache.send(:timestamped_filename).should == "foo_20000102030405.ext"
    end
  end
  
  describe "CachedDbFile :db_file association" do
    before(:each) { @cache = CachedDbFile.new }
    
    it "should call #build_db_file when association is nil" do
      @cache.should_receive(:build_db_file).once
      @cache.db_file
    end
  
    it "should not call #build_db_file when association exists" do
      @cache.db_file # autoload db_file assoc
      @cache.should_not_receive(:build_db_file)
      @cache.db_file
    end
  end
  
  describe "CachedDbFile :db_file association (re: delegation)" do
    before(:each) do
      @cache = CachedDbFile.new
      @db_file = mock('db_file')
      @db_file.stub!(:data=)
      @db_file.stub!(:data)
      @cache.stub!(:db_file).and_return(@db_file)
    end
    
    it "should be delegate for #data=" do
      @db_file.should_receive(:data=).with('foo').once
      @cache.data = 'foo'
    end
    
    it "should be delegate for #data" do
      @db_file.should_receive(:data).once
      @cache.data
    end
  end
  
  describe "new CachedDbFile (with no attributes)" do
    before(:each) { @cache = CachedDbFile.new }
    
    it { @cache.should_not be_valid}
    
    it "should raise error when sent #id_path" do
      lambda{ @cache.id_path }.should raise_error
    end
    
    it "should raise error when sent #cached_filename" do
      lambda{ @cache.cached_filename }.should raise_error
    end
  end
  
  describe "new CachedDbFile (with #filename)" do
    before(:each) { @cache = CachedDbFile.new(:filename => 'foo.txt')}
    
    it { @cache.should be_valid }
    
    it "should create db_file on save" do
      @cache.save
      DbFile.find(@cache.db_file_id).should == @cache.db_file
    end  
  end
  
  describe "saved CachedDbFile" do
    before do
      @foo_cache = CachedDbFile.create :filename => 'foo.txt', :db_file => DbFile.create(:data => 'foo')
    end
    
    before(:each) do
      @cache = CachedDbFile.find(@foo_cache.id)
    end
    
    it 'should return "#{id/10000}/#{id/100}/#{id}" when sent #id_path (e.g. "0/2/234" if id==234)' do
      id = @cache.id
      @cache.id_path.should == "#{id/10000}/#{id/100}/#{id}"
    end
    
    it 'should have #full_filename == "#{cached_db_file_root}/#{plural_model_name}/#{id_path}/#{timestamped_filename}"' do
      @cache.full_filename.should == "#{@cache.cached_db_file_root}/cached_db_file_spec/cached_db_files/#{@cache.id_path}/#{@cache.send(:timestamped_filename)}"
    end
    
    it 'should have #public_filename == "/#{plural_model_name}/#{id_path}/first_#{timestamp}.txt"' do
      @cache.public_filename.should == "/cached_db_file_spec/cached_db_files/#{@cache.id_path}/#{@cache.send(:timestamped_filename)}"
    end
  end
  
  describe "saved CachedDbFile (when there is no cached data)" do
    before do
      @foo_db_file = DbFile.create(:data => 'foo')
      @foo_cache = CachedDbFile.create :filename => 'foo.txt', :db_file => @foo_db_file
    end

    before(:each) do
      @foo_cache.class.remove_cache
      @cache = CachedDbFile.find(@foo_cache.id)
    end

    it "should access db_file when sent #full_filename" do
      @cache.should_receive(:db_file).once.and_return(@foo_db_file)
      @cache.full_filename
    end

    it "should create cached file when sent #full_filename" do
      File.exist?(@cache.full_filename).should == true
    end

    it "should create cached file when sent #public_filename" do
      @cache.public_filename
      File.exist?(@cache.cached_filename).should == true
    end

    it "should create the cached file with the data in db_file.data" do
      File.read(@cache.full_filename).should == @cache.data
    end
  end
  
  describe "saved CachedDbFile (when the data is cached)" do
    before do
      @foo_db_file = DbFile.create(:data => 'foo')
      @foo_cache = CachedDbFile.create :filename => 'foo.txt', :db_file => @foo_db_file
    end
    
    before(:each) do
      @foo_cache.class.remove_cache
      @foo_cache.send :write_cached_file
      @cache = CachedDbFile.find(@foo_cache.id)
    end
  
    it "should not access db_file when sent #full_filename" do
      @cache.should_not_receive(:db_file)
      @cache.full_filename
    end
  
    it "should not access db_file when sent #public_filename" do
      @cache.should_not_receive(:db_file)
      @cache.public_filename
    end
    
    it "should remove cached file on destroy" do
      @cache.destroy
      File.exist?(@cache.cached_filename).should == false
    end
  
    it "should remove cached file, and empty enclosing dirs, on update" do
      @cache.update_attributes :data => 'bar'
      File.exist?(@cache.cached_filename).should == false
    end
  
    it "should destroy db_file on destroy" do
      @cache.destroy
      lambda{ DbFile.find(@cache.db_file_id) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  
    it "should remove empty enclosing id dirs on remove_cached_file" do
      @cache.send :remove_cached_file
      path = @cache.cached_filename
      # path is like /0/0/1
      File.exist?(path = File.dirname(path)).should == false  
      File.exist?(path = File.dirname(path)).should == false
      File.exist?(path = File.dirname(path)).should == false
      File.exist?(path = File.dirname(path)).should == true
    end
  
    it "should update the cached file when data updated" do
      @cache.data = 'bar'
      @cache.save 
      File.read(@cache.full_filename).should == 'bar'
    end
  
    it "should re-cache when timestamp (updated_on, updated_at) has changed" do
      @cache.should_receive(:db_file).once.and_return(@foo_db_file)
      @foo_cache.save # updates updated_at
      @cache.reload.full_filename
    end
  end
  
  describe "CachedDbFile (when cache file is bad)" do
    before do
      @foo_cache = CachedDbFile.create :filename => 'foo.txt', :db_file => DbFile.create(:data => 'foo')
      @foo_cache.class.remove_cache
      @foo_cache.send :write_cached_file
      @cache = CachedDbFile.find(@foo_cache.id)
      @logger = mock('Logger')
      @logger.stub!(:info)
      @logger.stub!(:warn)
      @cache.stub!(:logger).and_return(@logger)
      `chmod -w #{File.dirname(@cache.cached_filename)}`
    end
      
    it "should log exceptions when destroying the cached file" do
      @cache.should_receive(:logger).twice.and_return(@logger)
      @cache.send :remove_cached_file
    end
  
    after(:each) do
      `chmod +w #{File.dirname(@cache.cached_filename)}`
    end
  end
end