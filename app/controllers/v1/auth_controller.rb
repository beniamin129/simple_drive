module V1
  class AuthController < ApplicationController
    skip_before_action :authenticate_request!, only: [ :create ]

    # POST /v1/auth/tokens
    def create
      begin
        token = AuthenticationService.generate_token
        render_success({
          token: token.token,
          expires_at: token.expires_at.utc.iso8601
        }, :created)
      rescue => e
        render_error("Failed to generate token", :internal_server_error)
      end
    end
  end
end
