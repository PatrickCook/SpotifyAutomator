class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # before_action :authenticate_request
  before_action :set_current_user
  before_action :ensure_spotify_user

  attr_reader :current_user

  private

  def set_current_user
    @current_user = User.find_by(email: "pcook")
    render json: { error: 'Could not load user' }, status: 400 unless @current_user
  end

  def authenticate_request
    @current_user = AuthorizeApiRequest.call(request.headers).result

    render json: { error: 'Not Authorized' }, status: 401 unless @current_user
  end

  def ensure_spotify_user
    @spotify_user = @current_user.spotify_user

    render json: { error: 'Could not load spotify user' }, status: 400 unless @spotify_user
  end
end
