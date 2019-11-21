class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :spotify_user

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def spotify_user
    @spotify_user ||= current_user&.spotify_user
  end

  def logged_in?
    !!session[:user_id]
  end

  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to access this section"
      redirect_to login_path
    end
  end

  def require_spotify_user
    unless spotify_user
      flash[:error] = "You must be authenticate with Spotify to access this section"
      redirect_to root_path
    end
  end
end
