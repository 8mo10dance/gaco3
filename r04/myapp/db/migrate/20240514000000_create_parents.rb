# db/migrate/20240514000000_create_parents.rb
class CreateParents < ActiveRecord::Migration[6.1]
  def change
    create_table :parents do |t|
      t.string :name
      t.string :delete_flag

      t.timestamps
    end
  end
end
