class SingleImportRecentlyPlayedWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id)
    user = User.find(user_id)

    spotify_recently_played(user).each do |track|
      artists = track.artists.map(&:name).join(", ")
      album_uri = track.album.images.last['url']
      genres = track.artists.map(&:genres).flatten
      user.played_tracks.create(
        name: track.name,
        artists: artists,
        album_uri: album_uri,
        genres: genres,
        uri: track.uri,
        played_at: track.played_at
      )
    end
  end

  private

  def spotify_recently_played(user)
    user.spotify_user&.recently_played(limit: 50, after: fetch_after_timestamp(user)) || []
  end

  def fetch_after_timestamp(user)
    max_timestamp = user.played_tracks.maximum("played_at")
    timestamp_to_milliseconds(max_timestamp)
  end

  def timestamp_to_milliseconds(timestamp)
    return 0 unless timestamp

    (timestamp.to_f * 1000).to_i
  end
end