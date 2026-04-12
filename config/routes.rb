Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => '/cable'

  get 'login', to: 'authentication#new'
  post 'login', to: 'authentication#login'
  delete 'logout', to: 'authentication#logout'
  get 'oauth/authorize/:provider', to: 'o_auth#authorize', as: 'oauth_authorize'
  get 'oauth/callback/:provider', to: 'o_auth#callback', as: 'oauth_callback'
  get 'verify_email', to: 'users#verify_email'
  post 'password_resets', to: 'password_resets#create'
  patch 'password_resets/:token', to: 'password_resets#update'

  resources :users, only: [:new, :create, :update, :destroy] do
    resources :linked_accounts, only: [:index, :show, :destroy]
  end

  resources :collections, only: [:index, :show, :create, :update, :destroy] do
    # Gardens will be / are fully REST-ful
    resources :gardens
  end

  # releases are also read-only, they're created via collections
  # annotations are under releases, so index shows all annotations for a release
  # hmm, release#show and annotations#index are awfully similar, oh well
  resources :releases, only: [:show] do
    resources :annotations, only: [:index, :create, :update, :destroy]
    resources :variants, only: [:index, :show, :create, :update, :destroy]
  end

  # playbacks can't be modified,
  # maybe move these under releases someday
  resources :playbacks, only: [:index, :show, :create ]
end
