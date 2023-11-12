Rails.application.routes.draw do
  resources :users

  namespace :api do
    namespace :v1 do
      resources :user_avatars, only: :create
    end
  end
end
