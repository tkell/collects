Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost', 'tide-pool.ca', 'www.tide-pool.ca', 'collects.tide-pool.ca'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
