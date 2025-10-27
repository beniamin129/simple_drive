require "test_helper"

class StorageServiceTest < ActiveSupport::TestCase
  test "create_adapter with database type" do
    storage_service = StorageService.new("database")

    assert_equal "database", storage_service.instance_variable_get(:@storage_type)
    assert_not_nil storage_service.instance_variable_get(:@adapter)
  end

  test "create_adapter with local type" do
    storage_service = StorageService.new("local")

    assert_equal "local", storage_service.instance_variable_get(:@storage_type)
  end

  test "store calls adapter store method" do
    storage_service = StorageService.new("database")
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    result = storage_service.store(blob_id, base64_data)

    assert_not_nil result
  end

  test "retrieve calls adapter retrieve method" do
    storage_service = StorageService.new("database")
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    storage_service.store(blob_id, base64_data)
    result = storage_service.retrieve(blob_id)

    assert_not_nil result
  end

  test "delete calls adapter delete method" do
    storage_service = StorageService.new("database")
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    storage_service.store(blob_id, base64_data)
    result = storage_service.delete(blob_id)

    assert result
  end

  test "exists? checks if blob exists" do
    storage_service = StorageService.new("database")
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    storage_service.store(blob_id, base64_data)

    assert storage_service.exists?(blob_id)
    assert_not storage_service.exists?("non-existent")
  end
end
