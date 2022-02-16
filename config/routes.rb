# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveQbOnline::Engine => '/', as: 'effective_qb_online'
end

EffectiveQbOnline::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
    get '/quickbooks/oauth/authorize', to: 'qb_oauth#authorize', as: :quickbooks_oauth
    get '/quickbooks/oauth/callback', to: 'qb_oauth#callback', as: :quickbooks_oauth_callback
  end

  namespace :admin do
    resources :qb_realms, only: [:edit, :update]

    resources :qb_receipts, only: [:edit, :update] do
      post :skip, on: :member
      post :sync, on: :member
    end

    get '/quickbooks', to: 'qb_online#index', as: :quickbooks
  end

end
