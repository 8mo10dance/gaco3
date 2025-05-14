# app/models/child.rb
class Child < ApplicationRecord
  belongs_to :parent, optional: true
  belongs_to :parent_include_deleted,
             -> { Parent.with_deleted },
             class_name: 'Parent',
             foreign_key: :parent_id,
             optional: true
end
