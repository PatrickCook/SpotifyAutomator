class CreateGenresPlayedTracksJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :genres, :played_tracks do |t|
      t.index :genre_id
      t.index :played_track_id
    end
  end
end
