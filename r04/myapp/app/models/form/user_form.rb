module Form
  class UserForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attr_accessor :name, :avatar

    def initialize(user = User.new, **attributes)
      @user = user
      super(attributes)
    end

    def save
      @user.attributes = user_attributes
      @user.save
    end

    private

    def user_attributes
      {
        name: name,
        avatar: avatar,
      }
    end
  end
end
