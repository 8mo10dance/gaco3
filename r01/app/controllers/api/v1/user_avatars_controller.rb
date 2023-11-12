module Api
  module V1
    class UserAvatarsController < ApplicationController
      def create
        user_avatar = UserAvatar.new(user_avatar_params)
        if user_avatar.invalid?
          return render json: { messages: user_avatar.errors.full_messages }, status: :unprocessable_entity
        end

        user_avatar.save!
        render json: { user_avatar_id: user_avatar.id }
      end

      private

      def user_avatar_params
        params.require(:user_avatar).permit(:image)
      end
    end
  end
end
