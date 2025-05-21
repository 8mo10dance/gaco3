class CreateTopics < ActiveRecord::Migration[6.1]
  def change
    create_table :topics do |t|
      t.string :title, null: false
      t.integer :parent_id, index: true

      t.timestamps
    end

    add_foreign_key :topics, :topics, column: :parent_id
  end
end
