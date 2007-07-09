Dependencies.load_paths << File.expand_path(File.join(File.dirname(__FILE__), 'fixtures/models'))

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :products, :force => true do |t|
      t.string :type
    end
    
    create_table :animals, :force => true do |t|
      t.string :type
    end
    
    create_table :vehicles, :force => true do |t|
      t.string :type
    end
    
    create_table :dwellings, :force => true do |t|
      t.string :type
    end
  end
end