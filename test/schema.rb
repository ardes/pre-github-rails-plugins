ActiveRecord::Schema.define(:version => 0) do
  create_table :secrets, :force => true do |t|
    t.column "text_crypt", :binary
    t.column "time_crypt", :binary
  end
end