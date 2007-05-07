module Ardes#:nodoc:
  module CachedDbFile
    def self.included(base)
      base.class_eval do
        cattr_accessor :cached_db_file_root, :cached_db_file_path
        self.cached_db_file_root = File.expand_path("#{RAILS_ROOT}/public")
        self.cached_db_file_path = name.underscore.pluralize
        
        db_file_class = (DbFile rescue Object.const_set(:DbFile, Class.new(ActiveRecord::Base)))
        base.belongs_to  :db_file, :class_name => db_file_class.name, :foreign_key => 'db_file_id'

        validates_presence_of :filename
        validates_presence_of :db_file, :on => :create
        # we don't want to load the :db_file by accessing it when validating update
        validates_presence_of :db_file_id, :on => :update
        
        after_destroy :remove_cached_file, :destroy_db_file
        after_save :remove_cached_file
        after_create :save_db_file
        
        delegate :data, :data=, :to => :db_file
        
        alias_method_chain :db_file, :build
      end
    end
       
    def db_file_with_build(*args)
      db_file_without_build(*args) || build_db_file
    end
  
    # returns the full path and filename of the (possibly non-existent) cached file
    def cached_filename
      raise RuntimeError, "Can't get cached_filename of a new record, save the record first" if id.nil?
      @cached_filename ||= File.expand_path(File.join(cached_db_file_root, cached_db_file_path, id_path, timestamped_filename))
    end
  
    # returns the full path of the cached filename, writing the file if it is not there
    def full_filename
      returning(cached_filename) {|f| write_cached_file unless File.exist?(f) }
    end
  
    # returns the uri part of the full_filename (writing the cached file if it is not there)
    def public_filename
      full_filename.sub cached_db_file_root, ''
    end

    # split id into hundreds so many files does not cause a problem with the OS-limit
    # of number of nodes per directory.  This scheme will accomodate 10 million records
    # before running into trouble with a per node limit of 1024.
    # 
    # Override this to provide your own scheme.
    def id_path
      "#{id/10000}/#{id/100}/#{id}"
    end
  
    # set the filename of the data
    def filename=(filename)
      @cached_filename = nil
      write_attribute :filename, filename.nil? ? nil : sanitize_filename(filename)
    end

  protected
    def save_db_file
      @db_file.save if @db_file
    end
    
    def destroy_db_file
      db_file.destroy
    end
  
    def timestamped_filename
      return filename unless time = (respond_to?(:updated_at) && updated_at) || (respond_to?(:updated_on) && updated_on)
      filename.sub(/(\.\w+)?$/) {|ext| "_#{time.strftime("%Y%m%d%H%M%S")}#{ext}"}
    end
    
    def sanitize_filename(filename)
      # taken from attachment_fu by Rick Olson
      returning filename.strip do |name|
        # NOTE: File.basename doesn't work right with Windows paths on Unix
        # get only the filename, not the whole path
        name.gsub! /^.*(\\|\/)/, ''
    
        # Finally, replace all non alphanumeric, underscore or periods with underscore
        name.gsub! /[^\w\.\-]/, '_'
      end
    end
  
    # writes the db_file.data to the cached_filename, first destroying the directory
    # to remove any old files (files with old timestamps)
    def write_cached_file
      remove_cached_file
      FileUtils.mkdir_p File.dirname(cached_filename)
      File.open(cached_filename, File::CREAT|File::TRUNC|File::WRONLY, 0644) do |f|
        f.write data
        f.close
      end
    end
  
    # Removes the file, and any empty enclosing directories.
    # Called in the after_destroy, and after_save callback
    def remove_cached_file
      return unless File.exist?(path = File.dirname(cached_filename))
      FileUtils.rm_r path
      path.sub! File.join(cached_db_file_root, cached_db_file_path), ''

      while (path = File.dirname(path)) != '' && Dir["#{path}/*"].empty?
        (FileUtils.rmdir File.join(cached_db_file_root, cached_db_file_path, path)) rescue nil
      end

    rescue
      logger.info "Exception destroying  #{path.inspect}: [#{$!.class.name}] #{$1.to_s}"
      logger.warn $!.backtrace.collect { |b| " > #{b}" }.join("\n")
    end
  end
end