Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :deployment, only: [ :create, :index, :show, :destroy ] do
    get :settings, on: :member
    resources :token, only: [ :create, :destroy, :index ], controller: :deployment_token
  end

  resources :deployment_container, only: [ :show ]

  scope :repo do
    get "/:repo_name/:filename", to: "helm/repo#download", constraints: { filename: /.*\.tgz/ }
    get "/:repo_name/index.yaml", to: "helm/repo#index_yaml", controller: "helm/repo"

    scope "/api" do
      # For namespaced resources, use module option
      resources :repo, only: [ :create, :destroy ], module: "helm", controller: "repo"
    end
  end

  resources :application, only: [ :new, :create, :destroy, :edit, :update ], controller: "project/project", as: :project do
    resources :version, only: [ :create, :destroy, :show, :update, :edit ], controller: "project/version" do
      post :publish, on: :member
      post :unpublish, on: :member

    end
  end

  resources :services, only: [ :create, :new, :show, :destroy, :update, :edit ], controller: "project/service",
            as: :project_services

  resources :team, only: [ :index, :create ]

  resources :user, only: [ :index ] do
    resources :ssh_key, only: [ :create, :destroy, :new ]
    delete :leave_team, on: :collection
  end

  namespace :api, path: "api/v1", defaults: { format: :json } do
    post :heartbeat, to: "ingress#heartbeat"
  end

  root "deployment#index"

  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: [ :sessions, :registrations ]

  # as :user do
  devise_scope :user do
    get "/users", to: "devise/sessions#new", as: :new_user_session
    post "/users/sign_in", to: "devise/sessions#create", as: :user_session
    delete "/users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
end
