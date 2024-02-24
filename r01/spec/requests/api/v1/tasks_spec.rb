require 'rails_helper'

RSpec.describe "Api::V1::Tasks", type: :request do
  describe "GET /api/v1/tasks" do
    subject { get '/api/v1/tasks' }

    before { create_list :task, 3 }

    it { is_expected.to eq 200 }
  end

  describe "POST /api/v1/tasks" do
    subject(:post_create) { post '/api/v1/tasks', params: { task: task_params } }

    context '正常系' do
      let(:task_params) { attributes_for :task }

      it { is_expected.to eq 200 }

      it { expect { post_create }.to change(Task, :count).by(1) }
    end

    context '準正常系' do
      let(:task_params) { attributes_for(:task, title: '') }

      it { is_expected.to eq 422 }

      it { expect { post_create }.not_to change(Task, :count) }
    end
  end

  describe "GET /api/v1/tasks/:id" do
    subject { get "/api/v1/tasks/#{task.id}" }

    let(:task) { create :task }

    it { is_expected.to eq 200 }
  end

  describe "PATCH /api/v1/tasks/:id" do
    subject(:patch_update) do
      patch "/api/v1/tasks/#{task.id}", params: { task: task_params }
    end

    let(:task) { create :task }

    before { task }

    context '正常系' do
      let(:task_params) { attributes_for :task }

      it { is_expected.to eq 200 }

      it 'Task の内容が更新される' do
        patch_update
        expect(task.reload.title).to eq task_params[:title]
      end
    end

    context '準正常系' do
      let(:task_params) { attributes_for :task, title: '' }

      it { is_expected.to eq 422 }

      it 'Task の内容が更新されない' do
        patch_update
        expect(task.reload.title).not_to eq task_params[:title]
      end
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    subject(:delete_destroy) { delete "/api/v1/tasks/#{task.id}" }

    let(:task) { create :task }

    before { task }

    it { is_expected.to eq 204 }

    it { expect { delete_destroy }.to change(Task, :count).by(-1) }
  end
end
