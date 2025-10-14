class CreatePublishLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :publish_logs do |t|
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end
  end
end
