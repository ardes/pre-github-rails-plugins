ActiveRecord::Schema.define(:version => 0) do
  create_table :props, :force => true do |t|
    t.column "foo_name", :string
    t.column "rating", :integer
    t.column "ratings", :string
  end
end
