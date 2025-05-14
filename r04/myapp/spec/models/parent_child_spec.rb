# spec/models/parent_child_spec.rb
require 'rails_helper'

RSpec.describe 'Parent and Child associations', type: :model do
  let!(:visible_parent) { Parent.create!(name: "Visible Parent", delete_flag: nil) }
  let!(:deleted_parent) { Parent.create!(name: "Deleted Parent", delete_flag: "1") }

  let!(:child1) { Child.create!(name: "Child One", parent: visible_parent) }
  let!(:child2) { Child.create!(name: "Child Two", parent: deleted_parent) }

  it 'default_scope excludes deleted parents' do
    expect(Parent.all).to contain_exactly(visible_parent)
  end

  it 'with_deleted includes deleted parents' do
    expect(Parent.with_deleted).to include(visible_parent, deleted_parent)
  end

  it 'child can access deleted parent using parent_include_deleted' do
    expect(child2.parent_include_deleted).to eq(deleted_parent)
  end

  it 'child cannot access deleted parent using regular parent association' do
    expect(child2.parent).to be_nil
  end
end
