require "test_helper"

class V1::BlobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = AuthenticationToken.generate.token

    @headers = {
      "Authorization" => "Bearer #{@token}",
      "Content-Type" => "application/json"
    }
  end

  test "POST /v1/blobs creates a blob" do
    blob_id = "test-blob-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    post "/v1/blobs",
      params: { id: blob_id, data: base64_data }.to_json,
      headers: @headers

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal blob_id, json_response["id"]
    assert_equal base64_data, json_response["data"]
    assert_not_nil json_response["size"]
    assert_not_nil json_response["created_at"]
  end

  test "POST /v1/blobs requires authentication" do
    post "/v1/blobs",
      params: { id: "test", data: Base64.encode64("test") }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "POST /v1/blobs rejects invalid base64" do
    post "/v1/blobs",
      params: { id: "test", data: "invalid base64!!!" }.to_json,
      headers: @headers

    assert_response :unprocessable_entity
  end

  test "GET /v1/blobs/:id retrieves a blob" do
    blob_id = "retrieve-blob-#{Time.now.to_i}"
    base64_data = Base64.encode64("Retrieve this")

    post "/v1/blobs",
      params: { id: blob_id, data: base64_data }.to_json,
      headers: @headers

    # Then retrieve it
    get "/v1/blobs/#{blob_id}", headers: @headers

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal blob_id, json_response["id"]
    assert_equal base64_data, json_response["data"]
    assert_not_nil json_response["size"]
    assert_not_nil json_response["created_at"]
  end

  test "GET /v1/blobs/:id returns 404 for non-existent blob" do
    get "/v1/blobs/non-existent", headers: @headers

    assert_response :not_found
  end

  test "DELETE /v1/blobs/:id deletes a blob" do
    blob_id = "delete-blob-#{Time.now.to_i}"
    base64_data = Base64.encode64("Delete this")

    post "/v1/blobs",
      params: { id: blob_id, data: base64_data }.to_json,
      headers: @headers

    delete "/v1/blobs/#{blob_id}", headers: @headers

    assert_response :no_content
  end

  test "DELETE /v1/blobs/:id returns 404 for non-existent blob" do
    delete "/v1/blobs/non-existent", headers: @headers

    assert_response :not_found
  end
end
