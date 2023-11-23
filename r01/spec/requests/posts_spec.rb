require 'rails_helper'

RSpec.describe "Posts", type: :request do
  describe 'GET /users/:user_id/posts' do
    subject { get "/users/#{user.id}/posts" }

    let(:user) { create :user }

    it { is_expected.to eq 200 }
  end

  describe 'GET /users/:user_id/posts/new' do
    subject { get "/users/#{user.id}/posts/new" }

    let(:user) { create :user }

    it { is_expected.to eq 200 }
  end

  describe 'POST /users/:user_id/posts' do
    subject(:post_create) { post "/users/#{user.id}/posts", params: { post: post_params } }

    let(:user) { create :user }
    let(:post_params) { attributes_for :post }

    it { expect { post_create }.to change(user.posts, :count).by 1 }

    it { is_expected.to redirect_to "/posts/#{user.posts.last.id}" }
  end

  describe 'GET /posts/:id' do
    subject { get "/posts/#{post.id}" }

    let(:post) { create :post }

    it { is_expected.to eq 200 }
  end

  describe 'GET /posts/:id/edit' do
    subject { get "/posts/#{post.id}/edit" }

    let(:post) { create :post }

    it { is_expected.to eq 200 }
  end

  describe 'PATCH /posts/:id' do
    subject(:patch_update) { patch "/posts/#{post.id}", params: { post: post_params } }

    let(:post) { create :post }
    let(:post_params) { attributes_for :post }

    it 'updates post' do
      patch_update
      expect(post.reload.content).to eq post_params[:content]
    end

    it { is_expected.to redirect_to "/posts/#{post.id}" }
  end

  describe 'DELETE /posts/:id' do
    subject(:delete_destroy) { delete "/posts/#{post.id}" }

    let(:post) { create :post }
    let(:user) { post.user }

    it { expect { delete_destroy }.to change(user.posts, :count).by(-1) }

    it { is_expected.to redirect_to "/users/#{user.id}/posts" }
  end
end
