# db/migrate/20240514000001_create_children.rb
class CreateChildren < ActiveRecord::Migration[6.1]
  def change
    create_table :children do |t|
      t.string :name
      t.references :parent, null: false, foreign_key: true

      t.timestamps
    end
  end
end
