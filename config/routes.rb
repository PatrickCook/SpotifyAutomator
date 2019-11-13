Rails.application.routes.draw do
  root 'welcome#index'

  post 'authenticate', to: 'authentication#authenticate'
  get '/auth/spotify/callback', to: 'authentication#spotify'

  get 'spotify', to: 'spotify#dashboard'
  get 'spotify/dashboard'
  get 'spotify/play_history'
  get 'spotify/recently_played'
  get 'spotify/refresh_recently_played'
  get 'spotify/generate_top_artists_playlist'
  get 'spotify/generate_top_songs_playlist'
end
