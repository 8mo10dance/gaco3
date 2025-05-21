class Topic < ApplicationRecord
  belongs_to :parent, class_name: "Topic", optional: true
  has_many :children, class_name: "Topic", foreign_key: "parent_id"

  scope :toplevel, -> { where(parent_id: nil) }
  scope :children, -> { where.not(parent_id: nil) }
  scope :has_children, -> { where(id: Topic.children.select(:parent_id)) }
  scope :has_children_2, -> { where(id: children.select(:parent_id)) }
  scope :has_children_fixed, -> { where(id: Topic.default_scoped.children.select(:parent_id)) }
end
