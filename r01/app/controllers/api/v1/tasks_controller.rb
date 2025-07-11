# frozen_string_literal: true

module Api
  module V1
    class TasksController < ApplicationController
      skip_before_action :verify_authenticity_token
      def index
        @tasks = Task.all
      end

      def create
        @task = Task.new(task_params)
        if @task.invalid?
          return render json: { messages: @task.errors.full_messages },
                        status: :unprocessable_entity
        end

        @task.save!
      end

      def show
        @task = Task.find(params[:id])
      end

      def update
        @task = Task.find(params[:id])
        @task.attributes = task_params
        if @task.invalid?
          return render json: { messages: @task.errors.full_messages },
                        status: :unprocessable_entity
        end

        @task.save!
      end

      def destroy
        @task = Task.find(params[:id])
        @task.destroy!
      end

      private

      def task_params
        params.require(:task).permit(:title, :content)
      end
    end
  end
end
