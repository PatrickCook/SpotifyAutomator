class User < ApplicationRecord
  serialize :spotify_hash, Hash
  has_many :played_tracks, dependent: :destroy

  has_secure_password

  #attr_reader :spotify_user

  def spotify_user
    RSpotify::User.new(spotify_hash) if spotify_hash.present?
  end
end
