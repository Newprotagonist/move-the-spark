Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "days#show"
  get "days/:date", to: "days#show", as: :day, constraints: { date: /\d{4}-\d{2}-\d{2}/ }
  get "weeks", to: "weeks#show", as: :current_week
  get "weeks/:date", to: "weeks#show", as: :week, constraints: { date: /\d{4}-\d{2}-\d{2}/ }

  resources :goals, except: [ :index, :show ] do
    member do
      post :complete
      post :uncomplete
      post :start_timer
      post :stop_timer
    end
  end

  resources :appointments, except: [ :show ]

  resources :shopping_lists do
    resources :shopping_list_items, only: [ :create ]
  end
  resources :shopping_list_items, only: [ :update, :destroy ]

  resource :settings, only: [ :edit, :update ], controller: "settings"
end
