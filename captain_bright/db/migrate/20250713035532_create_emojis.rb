class CreateEmojis < ActiveRecord::Migration[8.0]
  def change
    create_table :emojis do |t|
      t.string :body

      t.timestamps
    end
  end
end
