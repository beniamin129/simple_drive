require "test_helper"

class BlobTest < ActiveSupport::TestCase
  test "blob can be created with valid attributes" do
    blob = Blob.new(
      id: "test-blob-1",
      size: 100,
      created_at: Time.current
    )

    assert blob.valid?
  end

  test "blob requires id" do
    blob = Blob.new(size: 100, created_at: Time.current)
    assert_not blob.valid?
    assert_includes blob.errors[:id], "can't be blank"
  end

  test "blob requires size" do
    blob = Blob.new(id: "test-blob", created_at: Time.current)
    assert_not blob.valid?
    assert_includes blob.errors[:size], "can't be blank"
  end

  test "blob size must be greater than 0" do
    blob = Blob.new(id: "test-blob", size: 0, created_at: Time.current)
    assert_not blob.valid?
  end

  test "blob id must be unique" do
    Blob.create!(id: "duplicate-id", size: 100, created_at: Time.current)

    duplicate = Blob.new(id: "duplicate-id", size: 100, created_at: Time.current)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:id], "has already been taken"
  end

  test "blob sets created_at on create" do
    blob = Blob.create!(id: "auto-timestamp", size: 50)

    assert_not_nil blob.created_at
  end

  test "find_by_id! raises error when blob not found" do
    assert_raises ActiveRecord::RecordNotFound do
      Blob.find_by_id!("non-existent")
    end
  end

  test "data_size returns the size" do
    blob = Blob.create!(id: "size-test", size: 123)

    assert_equal 123, blob.data_size
  end
end
