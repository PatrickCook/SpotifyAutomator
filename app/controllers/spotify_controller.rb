class SpotifyController < ApplicationController
  before_action :require_login
  before_action :require_spotify_user, except: :spotify_callback

  def spotify_callback
    current_user.update(spotify_hash: request.env['omniauth.auth'])
    redirect_to spotify_dashboard_path
  end

  def dashboard
    @top_artists = @spotify_user.top_artists(limit: 30, time_range: "medium_term")
    @top_tracks = @spotify_user.top_tracks(limit: 30, time_range: "medium_term")
    genres = @top_artists.map { |a| a.genres }.flatten.group_by(&:itself).transform_values(&:count).to_a
    @top_genres = genres.sort_by(&:last).reverse.map(&:first).slice(0,10)
    @recently_played = @spotify_user.recently_played(limit: 50).sort_by(&:played_at)

    user_listening_data(params[:time_period])
    user_dow_data
    user_genres_data(params[:num_genres] || 5, params[:time_period])
  end

  def play_history
    @play_history = current_user.played_tracks.sort_by(&:played_at).reverse
  end

  def recently_played
    @recently_played = @spotify_user.recently_played(limit: 50)
  end

  def playlist_generation

  end

  def import_recently_played
    SingleImportRecentlyPlayedWorker.perform_async(current_user.id)

    respond_to do |format|
      format.html do
        flash[:notice] = "Your spotify recently played tracks are being imported."
        redirect_to spotify_play_history_path
      end

      format.json do
        render json: {
          action: "import_recently_played",
          status: "pending",
          message: "Your spotify recently played tracks are being imported"
        }
      end
    end
  end

  def generate_top_songs_playlist
    top_tracks = @spotify_user.top_tracks(limit: 30, time_range: params["time_range"])
    playlist = @spotify_user.create_playlist!("Spotify Automator: Top Tracks (#{params["time_range"]})")

    playlist.add_tracks!(top_tracks)
    flash[:notice] = "Playlist successfully created"
    redirect_to spotify_dashboard_path
  end

  def generate_top_artists_playlist

  end

  private

  def user_listening_data(time_period='month')
    @user_listening_data ||= ActiveRecord::Base.connection.execute(
      "SELECT total_plays.time_period,
              total_plays.plays as \"total\",
              new_plays.plays as \"new\",
              total_plays.plays - new_plays.plays as \"repeat\"
       FROM (
        SELECT DATE_TRUNC('#{time_period}', played_at)::DATE as \"time_period\", COUNT(*) as \"plays\" FROM played_tracks
        WHERE user_id = #{current_user.id}
        GROUP BY DATE_TRUNC('#{time_period}', played_at)
        ORDER BY DATE_TRUNC('#{time_period}', played_at)
        ) total_plays
      JOIN (
        SELECT DATE_TRUNC('#{time_period}', pt.played_at)::DATE as \"time_period\", COUNT(*) as \"plays\" FROM played_tracks pt
        JOIN (
          SELECT uri, MIN(played_at) as \"first\" FROM played_tracks WHERE user_id = 1 GROUP BY uri
        ) foo ON pt.uri = foo.uri AND pt.played_at = foo.first
        WHERE pt.user_id = #{current_user.id}
        GROUP BY DATE_TRUNC('#{time_period}', pt.played_at)
        ORDER BY DATE_TRUNC('#{time_period}', pt.played_at)
      ) new_plays
      ON total_plays.time_period = new_plays.time_period;"
    ).values
    @user_listening_data.unshift(['Week', 'Scrobbles', 'New Scrobbles', "Repeat Scrobbles"])
  end

  def user_genres_data(num_genres=5, time_period='week')
    header = users_top_genres(num_genres).flatten.unshift(time_period)
    @user_genres_data = [header]
    users_top_genres_data(num_genres, time_period).each_slice(num_genres) do |slice|
      normalized_data = header.slice(1,header.size-1).map do |genre|
        matched_genre = slice.select {|g| g[2] == genre}
        matched_genre.present? ? matched_genre[0][1] : 0
      end
      @user_genres_data += [[slice[0][0]] + normalized_data]
    end
    @user_genres_data
  end

  def users_top_genres_data(num_genres, time_period)
    ActiveRecord::Base.connection.execute(
      "SELECT DATE_TRUNC('#{time_period}', played_at)::DATE, COUNT(*), g.genre FROM played_tracks pt
      INNER JOIN genres_played_tracks gpt ON pt.id = gpt.played_track_id
      INNER JOIN genres g ON gpt.genre_id = g.id
      WHERE user_id = #{current_user.id} AND g.genre IN (
	      SELECT g.genre FROM played_tracks pt
	      INNER JOIN genres_played_tracks gpt ON pt.id = gpt.played_track_id
	      INNER JOIN genres g ON gpt.genre_id = g.id
	      WHERE user_id = #{current_user.id}
	      GROUP BY g.genre
        ORDER BY COUNT(*) desc
	      LIMIT #{num_genres}
      )
      GROUP BY DATE_TRUNC('#{time_period}', played_at), g.genre
      ORDER BY DATE_TRUNC('#{time_period}', played_at), g.genre;"
    ).values
  end

  def users_top_genres(num_genres)
    ActiveRecord::Base.connection.execute(
      "SELECT g.genre FROM played_tracks pt
	     INNER JOIN genres_played_tracks gpt ON pt.id = gpt.played_track_id
	     INNER JOIN genres g ON gpt.genre_id = g.id
       WHERE user_id = #{current_user.id}
       GROUP BY g.genre
       ORDER BY COUNT(*) DESC LIMIT #{num_genres};"
    ).values
  end

  def user_dow_data
    results = ActiveRecord::Base.connection.execute(
      "SELECT
        count(extract(dow from played_at) = 0 or null) as sunday,
        count(extract(dow from played_at) = 1 or null) as monday,
        count(extract(dow from played_at) = 2 or null) as tuesday,
        count(extract(dow from played_at) = 3 or null) as wednesday,
        count(extract(dow from played_at) = 4 or null) as thursday,
        count(extract(dow from played_at) = 5 or null) as friday,
        count(extract(dow from played_at) = 6 or null) as saturday
      FROM played_tracks
      WHERE user_id = #{current_user.id};"
    ).values

    @user_dow_data = [
      ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
      results[0]
    ]
  end
end
