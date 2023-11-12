require 'rails_helper'

RSpec.describe 'Api::V1::UserAvatars', type: :request do
  describe 'POST /api/v1/user_avatars' do
    subject(:post_create) { post '/api/v1/user_avatars', params: { user_avatar: user_avatar_params } }

    let(:user_avatar_params) do
      { image: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test_image.jpg'), 'image/jpeg') }
    end

    it { is_expected.to eq 200 }

    it { expect { post_create }.to change(UserAvatar, :count).by 1 }
  end
end
