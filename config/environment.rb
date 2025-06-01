# Load the Rails application.
require_relative "application"

# Load the app's custom and maybe _secret_ environment variables here, so that they are loaded before environments/*.rb
app_environment_variables = File.join(Rails.root, '.env')
load(app_environment_variables) if File.exist?(app_environment_variables)

# Initialize the Rails application.
Rails.application.initialize!
