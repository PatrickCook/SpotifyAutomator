class AddGenresAndAlbumArtworkToPlayedTrack < ActiveRecord::Migration[5.2]
  def change
    add_column :played_tracks, :genres, :string
    add_column :played_tracks, :album_uri, :string
  end
end
