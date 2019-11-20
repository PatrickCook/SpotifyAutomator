require 'rspotify/oauth'

Rails.application.config.to_prepare do
  OmniAuth::Strategies::Spotify.include SpotifyOmniauthExtension
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
           Rails.application.credentials.spotify[:client_id],
           Rails.application.credentials.spotify[:client_secret],
           scope: 'user-read-recently-played user-top-read user-read-email playlist-modify-public playlist-modify-private user-library-read user-library-modify'
end
