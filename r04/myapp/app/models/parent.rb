# app/models/parent.rb
class Parent < ApplicationRecord
  default_scope -> do
    where(delete_flag_default_scope)
  end

  scope :with_deleted, -> do
    scope = self.all
    scope = scope.unscope(where: delete_flag_default_scope)
    if scope.to_sql.include? delete_flag_default_scope.to_sql
      scope = scope.unscoped
    end
    scope
  end

  class << self
    def delete_flag_default_scope
      all.table[:delete_flag].eq(nil).or(all.table[:delete_flag].not_eq("1"))
    end
  end
end
