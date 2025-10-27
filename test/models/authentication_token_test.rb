require "test_helper"

class AuthenticationTokenTest < ActiveSupport::TestCase
  test "token can be generated" do
    token = AuthenticationToken.generate

    assert token.persisted?
    assert_not_nil token.token
    assert_not_nil token.expires_at
  end

  test "token requires token value" do
    token = AuthenticationToken.new(expires_at: 1.hour.from_now)

    assert_not token.valid?
    assert_includes token.errors[:token], "can't be blank"
  end

  test "token requires expires_at" do
    token = AuthenticationToken.new(token: "some-token")

    assert_not token.valid?
    assert_includes token.errors[:expires_at], "can't be blank"
  end

  test "generated token has 64 character hex string" do
    token = AuthenticationToken.generate

    assert_equal 64, token.token.length
  end

  test "token expires in 24 hours" do
    token = AuthenticationToken.generate

    assert token.expires_at > 23.hours.from_now
    assert token.expires_at < 25.hours.from_now
  end

  test "expired? returns true for expired token" do
    token = AuthenticationToken.create!(
      token: "expired-token",
      expires_at: 1.hour.ago
    )

    assert token.expired?
  end

  test "expired? returns false for valid token" do
    token = AuthenticationToken.generate

    assert_not token.expired?
  end

  test "still_valid? returns true for valid token" do
    token = AuthenticationToken.generate

    assert token.still_valid?
  end

  test "still_valid? returns false for expired token" do
    token = AuthenticationToken.create!(
      token: "expired-token",
      expires_at: 1.hour.ago
    )

    assert_not token.still_valid?
  end

  test "valid scope returns only non-expired tokens" do
    valid_token = AuthenticationToken.create!(
      token: "valid-token",
      expires_at: 1.hour.from_now
    )

    expired_token = AuthenticationToken.create!(
      token: "expired-token",
      expires_at: 1.hour.ago
    )

    valid_tokens = AuthenticationToken.valid
    assert_includes valid_tokens, valid_token
    assert_not_includes valid_tokens, expired_token
  end
end
