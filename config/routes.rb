Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "signup" => "users#new", as: :signup
  post "api/register" => "users#create", defaults: { format: :json }, as: :register
  get "signin" => "sessions#new", as: :login
  post "api/login" => "sessions#create", defaults: { format: :json }
  get "signout" => "sessions#destroy", as: :logout
  delete "api/logout" => "sessions#destroy", defaults: { format: :json }
  get "upload" => "uploads#new", as: :upload_file
  post "upload/file" => "uploads#create", as: :file
  post "api/upload/file" => "uploads#create", defaults: { format: :json }
  post "upload" => "uploads#new"
  get "files" => "uploads#index"
  get "api/files" => "uploads#index", defaults: { format: :json }
  delete "files/delete/:file_id" => "uploads#destroy", as: :user_file_delete
  delete "api/files/delete/:file_id" => "uploads#destroy", defaults: { format: :json }
  post "api/file/download/:user_id/:file_id" => "uploads#download", defaults: { format: :json }
  get "file/download/:user_id/:file_id" => "uploads#download", as: :user_download_option
  get "files/view/:user_id/:file_id" => "uploads#show", as: :user_view
  get "api/files/view/:user_id/:file_id" => "uploads#show", defaults: { format: :json }
  post "files/update/:file_id" => "uploads#update", as: :update_public
  put "api/files/update/:file_id" => "uploads#update", defaults: { format: :json }

  resources :users, only: [ :new, :create ]
  resources :sessions, only: [ :new, :create ]

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "uploads#index"
end
