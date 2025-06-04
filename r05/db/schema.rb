ActiveRecord::Schema.define(version: 0) do
  create_table :photos, force: :cascade do |t|
    t.string :image
    t.timestamps
  end
end
