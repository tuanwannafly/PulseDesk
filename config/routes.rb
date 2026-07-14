require 'sidekiq/web' if Rails.env.development?

Rails.application.routes.draw do
  # Sidekiq Web UI (development only)
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development?

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Auth
  get  '/signup',  to: 'users#new', as: :signup
  post '/signup',  to: 'users#create'
  get  '/login',   to: 'sessions#new', as: :login
  post '/login',   to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: :logout

  resources :users, only: %i[new create]

  resources :tickets do
    resources :ticket_messages, only: %i[create]
    member do
      post :claim
      post :resolve
      post :reopen
    end
  end

  resources :customers
  resources :tags, except: %i[show]

  # Dashboard
  get '/dashboard', to: 'dashboard#show', as: :dashboard

  # JSON API consumed by the React SPA
  namespace :api do
    post   '/auth/login',  to: 'auth#login'
    delete '/auth/login',  to: 'auth#logout'
    get    '/auth/me',     to: 'auth#me'

    resources :tickets do
      resources :messages, only: %i[create], controller: 'ticket_messages'
      member do
        post :claim
        post :resolve
        post :reopen
      end
    end

    resources :customers, only: %i[index show create]
    resources :tags,      only: %i[index create destroy]

    get '/dashboard', to: 'dashboard#index'
  end

  root 'tickets#index'
end
