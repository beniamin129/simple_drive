require "test_helper"

# Require service classes
require_relative "../../app/services/blob_service"
require_relative "../../app/services/authentication_service"
require_relative "../../app/services/storage_service"

class BlobServiceTest < ActiveSupport::TestCase
  setup do
    # Use database storage for testing
    @storage_service = StorageService.new("database")
    @blob_service = BlobService.new(@storage_service)
  end

  test "create_blob stores blob and metadata" do
    blob_id = "test-blob-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    result = @blob_service.create_blob(blob_id, base64_data)

    assert result[:success]
    assert_not_nil result[:blob]
    assert_equal blob_id, result[:blob].id
  end

  test "create_blob raises error for invalid base64" do
    blob_id = "invalid-blob"
    invalid_data = "Not a valid base64 string!!!"

    result = @blob_service.create_blob(blob_id, invalid_data)

    assert_not result[:success]
    assert_match(/Invalid/, result[:error])
  end

  test "create_blob raises error for duplicate id" do
    blob_id = "duplicate-blob-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    @blob_service.create_blob(blob_id, base64_data)

    result = @blob_service.create_blob(blob_id, base64_data)

    assert_not result[:success]
    assert_match(/already exists/, result[:error])
  end

  test "get_blob retrieves blob by id" do
    blob_id = "retrieve-blob-#{Time.now.to_i}"
    original_data = "Retrieve this"
    base64_data = Base64.encode64(original_data)

    @blob_service.create_blob(blob_id, base64_data)

    result = @blob_service.get_blob(blob_id)

    assert result[:success]
    assert_not_nil result[:blob]
    assert_equal blob_id, result[:blob].id
  end

  test "get_blob raises error for non-existent blob" do
    result = @blob_service.get_blob("non-existent-blob")

    assert_not result[:success]
    assert_match(/not found/, result[:error])
  end

  test "delete_blob removes blob" do
    blob_id = "delete-blob-#{Time.now.to_i}"
    base64_data = Base64.encode64("Delete this data")

    @blob_service.create_blob(blob_id, base64_data)

    result = @blob_service.delete_blob(blob_id)

    assert result[:success]

    get_result = @blob_service.get_blob(blob_id)
    assert_not get_result[:success]
  end

  test "delete_blob returns false for non-existent blob" do
    result = @blob_service.delete_blob("non-existent-blob")

    assert_not result[:success]
    assert_match(/not found/, result[:error])
  end
end
