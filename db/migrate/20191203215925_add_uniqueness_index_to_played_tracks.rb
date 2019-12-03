class AddUniquenessIndexToPlayedTracks < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      DELETE FROM played_tracks
      WHERE played_tracks.id IN (
        SELECT substring(dups.id_groups, 0, position(',' IN dups.id_groups))::INTEGER AS id
        FROM (
          SELECT array_to_string(array_agg(pt.id), ',') AS id_groups
          FROM played_tracks pt
          WHERE EXISTS (
            SELECT 1
            FROM played_tracks tmp
            WHERE tmp.user_id = pt.user_id AND tmp.name = pt.name AND tmp.played_at = pt.played_at
            LIMIT 1 OFFSET 1
          )
          GROUP BY pt.user_id, pt.name, pt.played_at
        ) AS dups
      );
    SQL

    add_index :played_tracks, [:user_id, :uri, :played_at], unique: true
  end

  def down
    remove_index :played_tracks, column: [:user_id, :uri, :played_at]
  end
end
