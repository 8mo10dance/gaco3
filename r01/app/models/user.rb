class User < ApplicationRecord
  has_one :avatar, class_name: 'UserAvatar', dependent: :destroy
end
