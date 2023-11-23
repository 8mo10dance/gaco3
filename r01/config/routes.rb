Rails.application.routes.draw do
  resources :users, shallow: true do
    resources :posts
  end

  namespace :api do
    namespace :v1 do
      resources :user_avatars, only: :create
    end
  end
end
