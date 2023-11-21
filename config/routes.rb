Rails.application.routes.draw do
  # Health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  get "/collections",     to: "collections#index"
  get "/collections/:id", to: "collections#show", as: 'collection'
  get "/gardens:id",      to: "gardens#show"
end
