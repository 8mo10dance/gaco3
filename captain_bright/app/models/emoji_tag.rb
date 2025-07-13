class EmojiTag < ApplicationRecord
  belongs_to :emoji
  belongs_to :tag
end
