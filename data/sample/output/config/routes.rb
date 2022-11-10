# frozen_string_literal: true

Rails.application.routes.draw do
  # Data Modeller: begin
  resources :employers
  root to: 'employers#index'
  resources :posts
  resources :users
  # Data Modeller: end
end
