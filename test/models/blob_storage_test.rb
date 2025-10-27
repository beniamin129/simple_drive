require "test_helper"

class BlobStorageTest < ActiveSupport::TestCase
  test "blob_storage can be created with valid attributes" do
    blob_storage = BlobStorage.new(
      id: "storage-1",
      data: "test data"
    )

    assert blob_storage.valid?
  end

  test "blob_storage requires id" do
    blob_storage = BlobStorage.new(data: "test data")

    assert_not blob_storage.valid?
    assert_includes blob_storage.errors[:id], "can't be blank"
  end

  test "blob_storage can store binary data" do
    binary_data = "Hello World".encode("ASCII-8BIT")
    blob_storage = BlobStorage.create!(id: "binary-test", data: binary_data)

    assert_equal binary_data, blob_storage.data
  end
end
