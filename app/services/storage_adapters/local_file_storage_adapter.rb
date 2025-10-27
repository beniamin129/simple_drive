# Local File System Storage Adapter
# Stores blob data in the local file system
class LocalFileStorageAdapter < StorageBackend
  def initialize(config = {})
    @storage_path = config[:storage_path] || ENV["LOCAL_STORAGE_PATH"] || Rails.root.join("storage", "blobs")
    ensure_storage_directory_exists
  end

  def store(id, data)
    return false unless valid_base64?(data)

    begin
      file_path = file_path_for_id(id)
      binary_data = decode_data(data)

      # Create directory if it doesn't exist
      FileUtils.mkdir_p(File.dirname(file_path))

      # Write binary data to file
      File.open(file_path, "wb") do |file|
        file.write(binary_data)
      end

      true
    rescue => e
      Rails.logger.error "Local file store error: #{e.message}"
      false
    end
  end

  def retrieve(id)
    begin
      file_path = file_path_for_id(id)
      return nil unless File.exist?(file_path)

      binary_data = File.read(file_path, mode: "rb")
      encode_data(binary_data)
    rescue => e
      Rails.logger.error "Local file retrieve error: #{e.message}"
      nil
    end
  end

  def delete(id)
    begin
      file_path = file_path_for_id(id)
      return false unless File.exist?(file_path)

      File.delete(file_path)
      true
    rescue => e
      Rails.logger.error "Local file delete error: #{e.message}"
      false
    end
  end

  def exists?(id)
    begin
      file_path = file_path_for_id(id)
      File.exist?(file_path)
    rescue => e
      Rails.logger.error "Local file exists? error: #{e.message}"
      false
    end
  end

  def size(id)
    begin
      file_path = file_path_for_id(id)
      return nil unless File.exist?(file_path)

      File.size(file_path)
    rescue => e
      Rails.logger.error "Local file size error: #{e.message}"
      nil
    end
  end

  private

  def file_path_for_id(id)
    # Create a nested directory structure based on the first 2 characters of the ID
    # This helps avoid having too many files in a single directory
    subdir = id[0, 2] || "00"
    File.join(@storage_path, subdir, "#{id}.blob")
  end

  def ensure_storage_directory_exists
    FileUtils.mkdir_p(@storage_path) unless Dir.exist?(@storage_path)
  end
end
