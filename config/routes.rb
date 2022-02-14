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
  end

end


# user_github_omniauth_authorize GET|POST  /users/auth/github(.:format)                                                             users/omniauth_callbacks#passthru
# user_github_omniauth_callback GET|POST  /users/auth/github/callback(.:format)                                                    users/omniauth_callbacks#github
