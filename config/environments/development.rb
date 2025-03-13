# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.enable_reloading = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.

  # Commenting this out for now, as it's causing build issues with Docker.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker if defined? Listen
  config.secret_key_base = '95bfdfa5ad84245fe7031b55a06c125f0621fc514d186c440ea493a630e7f07ed01347d4f485405ade8f184470413ada717bcb6ee32c741c1ae47996f7bac12a'
  config.mms_url = ENV['MMS_URL']
  config.mms_http_basic_username = ENV['MMS_BASIC_USERNAME']
  config.mms_http_basic_password = ENV['MMS_BASIC_PASSWORD']
  config.rels_ext_solr_url = ENV['RELS_EXT_SOLR_URL']
  config.repo_solr_url = ENV['REPO_SOLR_URL']

  config.iiif_host = 'https://iiif-qa.nypl.org'
end
