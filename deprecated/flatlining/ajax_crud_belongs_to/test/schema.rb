ActiveRecord::Schema.define(:version => 0) do
  create_table :ajax_crud_belongs_to_models, :force => true do |t|
    t.column "parent_id"
    t.column "name", :string
  end
end