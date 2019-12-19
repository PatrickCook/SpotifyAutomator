class ChangeGenresColumnOnPlayedTrack < ActiveRecord::Migration[5.2]
  def change
    rename_column :played_tracks, :genres, :old_genres
  end
end
