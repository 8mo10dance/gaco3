class Tag < ApplicationRecord
  has_many :emoji_tags
  has_many :emojis, through: :emoji_tags
end
