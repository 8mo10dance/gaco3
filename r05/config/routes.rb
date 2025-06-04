Rails.application.routes.draw do
  resources :photos, only: [:create]
end
