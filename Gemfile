# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'pg'
gem 'rails'
gem 'csv'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'http'
gem 'jbuilder'
gem 'mysql2'
gem 'net-http-digest_auth'
gem 'net-protocol'
gem 'nokogiri'
gem 'nypl_log_formatter'
gem 'redcarpet'
gem 'rsolr'
gem 'rsolr-ext'
gem 'rubydora'
gem 'stringio', '3.1.6'

gem 'aws-sdk-s3'
gem 'uglifier'
gem 'will_paginate'

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :test do
  gem 'shoulda-matchers'
  gem 'spring-commands-rspec'
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'pry'
  gem 'puma'
  gem 'rspec-rails'
  gem 'spring'
end

group :development do
  gem 'rubocop'
  gem 'web-console'
end
