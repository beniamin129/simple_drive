Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :v1 do
    # Authentication
    post "auth/tokens", to: "auth#create"

    # Blob storage
    resources :blobs, only: [ :index, :create, :show, :destroy ]

    # Storage backend info
    get "storage/backend", to: "storage#backend"
  end

  # Dashboard UI
  get "dashboard", to: "dashboard#index"

  # Defines the root path route ("/")
  root "dashboard#index"
end
