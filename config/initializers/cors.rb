# As of Dec 7, we're only install this gem in dev
# We'll need a better (and more secure!) version of this before we deploy
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :patch, :put]
  end
end
