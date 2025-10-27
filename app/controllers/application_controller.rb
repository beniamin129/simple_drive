class ApplicationController < ActionController::API
  before_action :authenticate_request!

  private

  def authenticate_request!
    token = AuthenticationService.extract_token_from_header(request.headers["Authorization"])

    unless AuthenticationService.authenticate(token)
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end

  def render_success(data, status = :ok)
    render json: data, status: status
  end
end
