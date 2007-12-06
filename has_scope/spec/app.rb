ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :scope_spec_models, :force => true do |t|
      t.boolean :published, :default => false, :null => false
    end
  end
end

class ScopeSpecModel < ActiveRecord::Base
  has_scope :published, :find => {:conditions => {:published => true}}, :create => {:published => true}
end