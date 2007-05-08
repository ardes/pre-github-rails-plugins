## APP SETUP

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :cached_db_file_spec_db_files, :force => true do |t|
      t.column "data", :binary
    end
    
    create_table :cached_db_file_spec_cached_db_files, :force => true do |t|
      t.column "db_file_id", :integer
      t.column "filename", :string
      t.column "updated_at", :datetime
    end
  end
end

require 'ardes/cached_db_file'

module CachedDbFileSpec  
  class DbFile < ActiveRecord::Base
    self.table_name = 'cached_db_file_spec_db_files'
  end
  
  class CachedDbFile < ActiveRecord::Base
    self.table_name = 'cached_db_file_spec_cached_db_files'
    include Ardes::CachedDbFile
    self.cached_db_file_root = File.expand_path(File.join(File.dirname(__FILE__), 'public'))

    class<<self
      def remove_cache
        FileUtils.rm_rf self.cached_db_file_root
      end
    end
  end
end