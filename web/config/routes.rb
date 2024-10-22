Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :dashboard, only: [ :index ]

  root "dashboard#index"

  # devise_for :users,
  #            controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
  #            skip: [ :sessions, :registrations ]
  #
  # # as :user do
  # devise_scope :user do
  #   get "/users", to: "devise/sessions#new", as: :new_user_session
  #   post "/users/sign_in", to: "devise/sessions#create", as: :user_session
  #   delete "/users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  # end
end
