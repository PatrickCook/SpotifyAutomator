class AuthenticationController < ApplicationController
  # skip_before_action :authenticate_request

  def authenticate
    command = AuthenticateUser.call(params[:email], params[:password])

    if command.success?
      render json: { auth_token: command.result }
    else
      render json: { error: command.errors }, status: :unauthorized
    end
  end

  def spotify
    @current_user.update(spotify_hash: request.env['omniauth.auth'])

    redirect_to spotify_dashboard_path
  end
end