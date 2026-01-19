Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get 'login', to: 'authentication#new'
  post 'login', to: 'authentication#login'
  delete 'logout', to: 'authentication#logout'
  get 'oauth/authorize/:provider', to: 'o_auth#authorize', as: 'oauth_authorize'
  get 'oauth/callback/:provider', to: 'o_auth#callback', as: 'oauth_callback'
  resources :users, only: [:new, :create, :update, :destroy] do
    resources :linked_accounts, only: [:index, :show, :destroy]
  end

  # Collections are read-only, and are created and loaded from Rake tasks
  resources :collections, only: [:index, :show, :destroy] do
    # Gardens will be / are fully REST-ful
    resources :gardens
  end

  # releases are also read-only,
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
