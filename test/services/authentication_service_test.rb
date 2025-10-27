require "test_helper"

class AuthenticationServiceTest < ActiveSupport::TestCase
  test "authenticate returns true for valid token" do
    token_obj = AuthenticationToken.generate
    token_value = token_obj.token

    result = AuthenticationService.authenticate(token_value)

    assert result
  end

  test "authenticate returns false for invalid token" do
    result = AuthenticationService.authenticate("invalid-token")

    assert_not result
  end

  test "authenticate returns false for expired token" do
    token_obj = AuthenticationToken.create!(
      token: "expired-token",
      expires_at: 1.hour.ago
    )

    result = AuthenticationService.authenticate("expired-token")

    assert_not result
  end

  test "generate_token creates new token" do
    token = AuthenticationService.generate_token

    assert_not_nil token
    assert_not_nil token.token
    assert_not_nil token.expires_at
  end
end
