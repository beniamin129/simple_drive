require "test_helper"

class V1::AuthControllerTest < ActionDispatch::IntegrationTest
  test "POST /v1/auth/tokens generates a token" do
    post "/v1/auth/tokens"

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_not_nil json_response["token"]
    assert_not_nil json_response["expires_at"]
  end

  test "generated token is valid and can be used for authentication" do
    post "/v1/auth/tokens"

    json_response = JSON.parse(response.body)
    token = json_response["token"]

    token_obj = AuthenticationToken.find_by(token: token)
    assert_not_nil token_obj
    assert token_obj.still_valid?
  end

  test "token expires in 24 hours" do
    post "/v1/auth/tokens"

    json_response = JSON.parse(response.body)
    expires_at = Time.parse(json_response["expires_at"])

    assert expires_at > 23.hours.from_now
    assert expires_at < 25.hours.from_now
  end
end
