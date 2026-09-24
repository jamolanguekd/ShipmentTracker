Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :shipments do
        resources :tracking_events, only: [:index, :create]
      end

      resources :webhook_endpoints do
        resources :deliveries, only: [:index], controller: "webhook_deliveries"
      end
    end
  end
end
