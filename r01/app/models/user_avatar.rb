class UserAvatar < ApplicationRecord
  belongs_to :user, optional: true

  mount_uploader :image, AvatarUploader
end
