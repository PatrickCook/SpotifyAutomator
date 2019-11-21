class User < ApplicationRecord
  has_secure_password

  serialize :spotify_hash, Hash
  has_many :played_tracks, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  def spotify_user
    RSpotify::User.new(spotify_hash) if spotify_hash.present?
  end
end
