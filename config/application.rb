# frozen_string_literal: true

require_relative 'boot'

require 'uri'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FedoraIngestRails
  class Application < Rails::Application
    config.autoload_paths << Rails.root.join('lib')
  end
end
