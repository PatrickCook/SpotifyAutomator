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
    user_genres_data
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

  def user_genres_data(num_genres=5, time_period='week')
    @genres_data = [users_top_genres.flatten.unshift(time_period)]
    users_top_genres_data(num_genres, time_period).each_slice(num_genres) do |slice|
      @genres_data += [[slice[0][0]] + slice.map{ |i| i[1] }]
    end
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

  def users_top_genres
    ActiveRecord::Base.connection.execute(
      "SELECT g.genre FROM played_tracks pt
	     INNER JOIN genres_played_tracks gpt ON pt.id = gpt.played_track_id
	     INNER JOIN genres g ON gpt.genre_id = g.id
       WHERE user_id = #{current_user.id}
       GROUP BY g.genre
       ORDER BY COUNT(*) DESC LIMIT 5;"
    ).values
  end
end
