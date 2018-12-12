# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!


# Constants common to all environments
IMAGE_TILECUTTING_SERVICE_URL = ENV['IMAGE_TILECUTTING_SERVICE_URL']