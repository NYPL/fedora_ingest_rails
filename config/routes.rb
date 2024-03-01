# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'image_filestore_entries/status/:file_id' => 'image_filestore_entries#status'
  get 'changelog' => 'changelog#index'
  post 'single_field_updates', to: 'single_field_updates#update_fields'

  resources :ingest_requests, only: [:create], defaults: { format: :json }
  resources :ingest_history, only: [:show], defaults: { format: :json }
  resource :stats, only: [:show], defaults: { format: :json }
end
