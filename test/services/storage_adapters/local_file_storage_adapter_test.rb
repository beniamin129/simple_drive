require "test_helper"

class LocalFileStorageAdapterTest < ActiveSupport::TestCase
  setup do
    @adapter = LocalFileStorageAdapter.new
    @test_dir = Rails.root.join("storage", "blobs", "test")
    FileUtils.mkdir_p(@test_dir)
  end

  teardown do
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
  end

  test "store saves data to local file system" do
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    result = @adapter.store(blob_id, base64_data)

    assert result
    assert @adapter.exists?(blob_id)
  end

  test "retrieve gets data from local file system" do
    blob_id = "test-#{Time.now.to_i}"
    original_data = "Retrieve this"
    base64_data = Base64.encode64(original_data)

    @adapter.store(blob_id, base64_data)
    retrieved_data = @adapter.retrieve(blob_id)

    assert_equal base64_data.strip, retrieved_data
  end

  test "retrieve returns nil for non-existent blob" do
    result = @adapter.retrieve("non-existent")

    assert_nil result
  end

  test "delete removes data from local file system" do
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Delete this")

    @adapter.store(blob_id, base64_data)
    assert @adapter.exists?(blob_id)

    result = @adapter.delete(blob_id)

    assert result
    assert_not @adapter.exists?(blob_id)
  end

  test "exists? checks if blob exists in file system" do
    blob_id = "test-#{Time.now.to_i}"
    base64_data = Base64.encode64("Test data")

    @adapter.store(blob_id, base64_data)

    assert @adapter.exists?(blob_id)
    assert_not @adapter.exists?("non-existent")
  end

  test "size returns file size" do
    blob_id = "test-#{Time.now.to_i}"
    original_data = "Test data"
    base64_data = Base64.encode64(original_data)

    @adapter.store(blob_id, base64_data)
    size = @adapter.size(blob_id)

    assert_equal original_data.length, size
  end
end
