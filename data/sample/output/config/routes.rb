# frozen_string_literal: true

Rails.application.routes.draw do
  # Data Modeller: begin
  resources :users
  root to: 'users#index'
  resources :employers
  resources :posts
  # Data Modeller: end
end
