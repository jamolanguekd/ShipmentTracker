Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :shipments do
        resources :tracking_events, only: [:index, :create]
      end
    end
  end
end
