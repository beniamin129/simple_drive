# Database Storage Adapter
# Stores blob data in a separate database table
class DatabaseStorageAdapter < StorageBackend
  def initialize(config = {})
    # Configuration can be used for different databases or connection settings
    @config = config
  end

  def store(id, data)
    return false unless valid_base64?(data)

    begin
      # Store the Base64 encoded data directly
      BlobStorage.find_or_initialize_by(id: id).tap do |blob_storage|
        blob_storage.data = data
        blob_storage.save!
      end
      true
    rescue => e
      Rails.logger.error "Database store error: #{e.message}"
      false
    end
  end

  def retrieve(id)
    begin
      blob_storage = BlobStorage.find_by(id: id)
      return nil unless blob_storage

      blob_storage.data
    rescue => e
      Rails.logger.error "Database retrieve error: #{e.message}"
      nil
    end
  end

  def delete(id)
    begin
      blob_storage = BlobStorage.find_by(id: id)
      return false unless blob_storage

      blob_storage.destroy!
      true
    rescue => e
      Rails.logger.error "Database delete error: #{e.message}"
      false
    end
  end

  def exists?(id)
    begin
      BlobStorage.exists?(id: id)
    rescue => e
      Rails.logger.error "Database exists? error: #{e.message}"
      false
    end
  end

  def size(id)
    begin
      blob_storage = BlobStorage.find_by(id: id)
      return nil unless blob_storage

      # Calculate size from Base64 data
      decode_data(blob_storage.data).bytesize
    rescue => e
      Rails.logger.error "Database size error: #{e.message}"
      nil
    end
  end
end
