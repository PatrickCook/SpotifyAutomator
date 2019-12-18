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
end
