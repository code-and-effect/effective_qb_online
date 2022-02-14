# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveQbOnline::Engine => '/', as: 'effective_qb_online'
end

EffectiveQbOnline::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
  end

  namespace :admin do
  end

end
