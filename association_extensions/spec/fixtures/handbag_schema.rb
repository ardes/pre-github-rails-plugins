ActiveRecord::Schema.define(:version => 0) do
  create_table :handles, :force => true do |t|
    t.column "container_id", :integer
  end

  create_table :things, :force => true do |t|
    t.column "handbag_id", :integer
  end

  create_table :handbags, :force => true do |t|
    t.column "owner_id", :integer
  end

  create_table :owner, :force => true do |t|
  end
end
