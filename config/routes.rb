Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   resources :ingest_requests, only: [:create], defaults: {format: :json}
   resources :ingest_history, only: [:show], defaults: {format: :json}
   resource :stats, only: [:show], defaults: {format: :json}
end
