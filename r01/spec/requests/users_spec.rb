require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users' do
    subject(:get_index) { get '/users' }

    before { create_list :user, 3 }

    it { is_expected.to eq 200 }
  end

  describe 'GET /users/new' do
    subject(:get_new) { get '/users/new' }

    it { is_expected.to eq 200 }
  end

  describe 'POST /users' do
    subject(:post_create) { post '/users', params: { user: user_params } }

    let(:user_params) { attributes_for :user }

    it { expect { post_create }.to change(User, :count).by 1 }

    it { is_expected.to redirect_to "/users/#{User.last.id}" }
  end

  describe 'GET /users/:id' do
    subject(:get_show) { get "/users/#{user.id}" }

    let(:user) { create :user }

    it { is_expected.to eq 200 }
  end

  describe 'GET /users/:id/edit' do
    subject(:get_edit) { get "/users/#{user.id}/edit" }

    let(:user) { create :user }

    it { is_expected.to eq 200 }
  end

  describe 'PATCH /users/:id' do
    subject(:patch_update) { patch "/users/#{user.id}", params: { user: user_params } }

    let(:user) { create :user }
    let(:user_params) { attributes_for :user }

    it { expect { patch_update }.to change { user.reload.name }.to eq user_params[:name] }

    it { is_expected.to redirect_to "/users/#{user.id}" }
  end

  describe 'DELETE /users/:id' do
    subject(:delete_destroy) { delete "/users/#{user.id}" }

    let(:user) { create :user }

    before { user }

    it { expect { delete_destroy }.to change(User, :count).by -1 }

    it { is_expected.to redirect_to '/users' }
  end
end
