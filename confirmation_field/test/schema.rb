ActiveRecord::Schema.define(:version => 0) do
  create_table :confirmation_field_models, :force => true do |t|
    t.column "name", :string
    t.column "email", :string
    t.column "password", :string
  end
end