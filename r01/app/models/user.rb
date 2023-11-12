class User < ApplicationRecord
  has_one :avatar, class_name: 'UserAvatar', dependent: :destroy

  attribute :avatar_id, :integer

  def avatar_id=(avatar_id)
    super(avatar_id)
    self.avatar = UserAvatar.find_by(id: avatar_id)
  end

  def avatar_id
    avatar&.id
  end
end
