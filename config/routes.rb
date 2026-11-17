Rails.application.routes.draw do
  get "health", to: "health#show"

  resources :orders, only: [:create, :show] do
    member do
      post :payment
      post :delivery
      post :payout
      post :refund
    end

    resources :disputes, only: [:create]
  end

  resources :disputes, only: [] do
    member do
      post :resolve
    end
  end

  namespace :support do
    resources :cases, only: [:show, :index], param: :order_id
  end
end
