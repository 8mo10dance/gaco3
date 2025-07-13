class Emoji < ApplicationRecord
  has_many :emoji_tags
  has_many :tags, through: :emoji_tags
end
