Rails.application.routes.draw do


  root 'welcome#index'
  resources :users
  resources :sessions, only: [:new, :create, :destroy]

  get 'signup', to: 'users#new', as: 'signup'
  get 'login', to: 'sessions#new', as: 'login'
  get 'logout', to: 'sessions#destroy', as: 'logout'

  get '/auth/spotify/callback', to: 'spotify#spotify_callback'

  get 'spotify', to: 'spotify#dashboard'
  get 'spotify/dashboard'
  get 'spotify/play_history'
  get 'spotify/recently_played'
  get 'spotify/import_recently_played'
  get 'spotify/generate_top_artists_playlist'
  get 'spotify/generate_top_songs_playlist'
end
