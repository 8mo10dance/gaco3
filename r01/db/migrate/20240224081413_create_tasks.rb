# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks, comment: 'タスク' do |t|
      t.string :title, null: false, default: '', comment: 'タイトル'
      t.text :content, null: false, comment: '内容'

      t.timestamps
    end
  end
end
