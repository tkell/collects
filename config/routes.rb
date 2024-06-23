Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post 'login', to: 'authentication#login'

  # Collections are read-only, and are created and loaded from Rake tasks
  resources :collections, only: [:index, :show] do
    # Gardens will be / are fully REST-ful
    resources :gardens
  end
end
