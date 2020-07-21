# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'pg', '>= 0.18', '< 2.0'
gem 'rails', '~> 5.2.4'
# gem 'sass-rails', '~> 5.0'
gem 'daemons', '~> 1.2', '>= 1.2.6'
gem 'delayed_job_active_record', '~> 4.1', '>= 4.1.2'
gem 'http', '~> 3.0'
gem 'jbuilder', '~> 2.5'
gem 'mysql2', '~> 0.4.5' # used to connect to Filestore Databases
gem 'net-http-digest_auth', '~> 1.4.1'
gem 'nypl_log_formatter', '~> 0.1.2'
gem 'rsolr', '~> 1.0.10'
gem 'rsolr-ext', '~> 1.0.3'
gem 'rubydora', '~> 2.0'
gem 'uglifier', '>= 1.3.0'
gem 'will_paginate', '~> 3.1', '>= 3.1.6'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :test do
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.2'
end

group :development, :test do
  gem 'factory_bot_rails', '~> 4.8', '>= 4.8.2'
  gem 'pry', '~> 0.11.3'
  gem 'puma', '~> 3.7'
  gem 'rspec-rails', '~> 3.7', '>= 3.7.2'
end

group :development do
  gem 'rubocop', '~> 0.54.0'
  gem 'rubocop-rspec'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  # Commenting these out because of the build issues it created with Docker.
  # gem 'listen', '~> 3.0.5'
  # # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end
