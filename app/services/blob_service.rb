class BlobService
  def initialize(storage_service = nil)
    @storage_service = storage_service || StorageService.new
    @storage_type = @storage_service.backend_name
  end

  def create_blob(id, data)
    return { success: false, error: "Invalid ID" } if id.blank?
    return { success: false, error: "Invalid data" } unless valid_base64?(data)

    if Blob.exists?(id: id)
      return { success: false, error: "Blob with this ID already exists" }
    end

    size = calculate_data_size(data)

    begin
      blob = Blob.create!(
        id: id,
        size: size,
        storage_type: @storage_type,
        created_at: Time.current
      )
    rescue ActiveRecord::RecordInvalid => e
      return { success: false, error: e.message }
    end

    unless @storage_service.store(id, data)
      blob.destroy
      return { success: false, error: "Failed to store blob data" }
    end

    { success: true, blob: blob }
  end

  def get_blob(id)
    blob = Blob.find_by(id: id)
    return { success: false, error: "Blob not found" } unless blob

    storage_type = blob.storage_type || Rails.application.config.storage_backend
    storage_config = get_storage_config_for(storage_type)

    correct_storage_service = StorageService.new(storage_type, storage_config)

    data = correct_storage_service.retrieve(id)
    return { success: false, error: "Failed to retrieve blob data" } unless data

    blob.data = data

    { success: true, blob: blob }
  end

  def delete_blob(id)
    blob = Blob.find_by(id: id)
    return { success: false, error: "Blob not found" } unless blob

    storage_type = blob.storage_type || Rails.application.config.storage_backend
    storage_config = get_storage_config_for(storage_type)

    correct_storage_service = StorageService.new(storage_type, storage_config)

    unless correct_storage_service.delete(id)
      return { success: false, error: "Failed to delete blob data" }
    end

    blob.destroy

    { success: true }
  end

  def blob_exists?(id)
    Blob.exists?(id: id) && @storage_service.exists?(id)
  end

  def get_blob_size(id)
    blob = Blob.find_by(id: id)
    return nil unless blob

    storage_size = @storage_service.size(id)
    storage_size || blob.size
  end

  private

  def get_storage_config_for(storage_type)
    all_configs = Rails.application.config.all_storage_configs || {}
    backend_config = all_configs[storage_type] || {}

    if storage_type == "s3"
      region = ENV["S3_REGION"] || backend_config["region"] || "us-east-1"
      backend_config = {
        "endpoint" => ENV["S3_ENDPOINT"] || backend_config["endpoint"] || "https://s3.#{region}.amazonaws.com",
        "bucket" => ENV["S3_BUCKET"] || backend_config["bucket"],
        "access_key" => ENV["S3_ACCESS_KEY"] || backend_config["access_key"],
        "secret_key" => ENV["S3_SECRET_KEY"] || backend_config["secret_key"],
        "region" => region
      }
    elsif storage_type == "ftp"
      backend_config = {
        "host" => ENV["FTP_HOST"] || backend_config["host"],
        "username" => ENV["FTP_USERNAME"] || backend_config["username"],
        "password" => ENV["FTP_PASSWORD"] || backend_config["password"],
        "port" => ENV["FTP_PORT"] || backend_config["port"] || 21,
        "remote_path" => ENV["FTP_REMOTE_PATH"] || backend_config["remote_path"] || "/blobs",
        "passive" => ENV["FTP_PASSIVE"] != "false" && backend_config["passive"] != false
      }
    elsif storage_type == "local"
      backend_config = {
        "storage_path" => backend_config["storage_path"] || Rails.root.join("storage", "blobs")
      }
    end

    backend_config
  end

  def valid_base64?(data)
    return false if data.nil? || data.empty?

    # Remove whitespace and check if it's valid Base64
    cleaned_data = data.strip

    # Check if the string contains only valid Base64 characters
    return false unless cleaned_data =~ /\A[A-Za-z0-9+\/=]*\z/

    # Check if the length is a multiple of 4 (properly padded Base64)
    return false unless cleaned_data.length % 4 == 0

    begin
      # Try to decode - this is the definitive check
      decoded = Base64.decode64(cleaned_data)
      # Also check that re-encoding gives us the same result
      reencoded = Base64.encode64(decoded).strip
      cleaned_data == reencoded || cleaned_data == reencoded.gsub(/=+$/, "")
    rescue ArgumentError
      false
    end
  end

  def calculate_data_size(data)
    Base64.decode64(data).bytesize
  end
end
