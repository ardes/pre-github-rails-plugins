ActiveRecord::Schema.define(:version => 0) do
  create_table :ajax_crud_sortable_models, :force => true do |t|
    t.column "name", :string
    t.column "position", :integer
  end
end