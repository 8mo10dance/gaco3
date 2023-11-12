class CreateUserAvatars < ActiveRecord::Migration[7.0]
  def change
    create_table :user_avatars do |t|
      t.references :user, foreign_key: true
      t.string :image, null: false

      t.timestamps
    end
  end
end
