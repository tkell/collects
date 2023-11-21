Rails.application.routes.draw do
  # Health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Collections are read-only, and are created and loaded from Rake tasks
  # Items are also created by Rake tasks
  resources :collections, only: [:index, :show] do
    # Gardens are fully REST-ful
    resources :gardens
  end
end
