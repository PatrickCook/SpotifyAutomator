class BackfillGenresFromPlayedTracks < ActiveRecord::Migration[5.2]
  def up
    tracks_wo_genres = PlayedTrack.pluck(:uri).map{ |id| id.split(':')[2] }
    tracks_wo_genres.each_slice(50) do |batch|
      RSpotify::Track.find(batch).each do |track|
        genres = track.artists.map(&:genres).flatten.map{ |g| Genre.find_or_create_by(genre: g) }
        PlayedTrack.where(uri: track.uri).each do |track|
          track.genres << genres
        end
      end
    end
  end

  def down
    Genre.destroy_all
  end
end
