# Abstract base class for storage backends
# Implements Strategy Pattern for different storage implementations
class StorageBackend
  # Store blob data and return success status
  # @param id [String] Unique identifier for the blob
  # @param data [String] Base64 encoded data
  # @return [Boolean] Success status
  def store(id, data)
    raise NotImplementedError, "Subclasses must implement #store method"
  end

  # Retrieve blob data
  # @param id [String] Unique identifier for the blob
  # @return [String, nil] Base64 encoded data or nil if not found
  def retrieve(id)
    raise NotImplementedError, "Subclasses must implement #retrieve method"
  end

  # Delete blob data
  # @param id [String] Unique identifier for the blob
  # @return [Boolean] Success status
  def delete(id)
    raise NotImplementedError, "Subclasses must implement #delete method"
  end

  # Check if blob exists
  # @param id [String] Unique identifier for the blob
  # @return [Boolean] True if blob exists
  def exists?(id)
    raise NotImplementedError, "Subclasses must implement #exists? method"
  end

  # Get blob size in bytes
  # @param id [String] Unique identifier for the blob
  # @return [Integer, nil] Size in bytes or nil if not found
  def size(id)
    raise NotImplementedError, "Subclasses must implement #size method"
  end

  protected

  # Validate Base64 data
  # @param data [String] Base64 encoded data
  # @return [Boolean] True if valid Base64
  def valid_base64?(data)
    return false if data.nil? || data.empty?

    begin
      Base64.decode64(data)
      true
    rescue ArgumentError
      false
    end
  end

  # Decode Base64 data and return binary
  # @param data [String] Base64 encoded data
  # @return [String] Binary data
  def decode_data(data)
    Base64.decode64(data)
  end

  # Encode binary data to Base64
  # @param data [String] Binary data
  # @return [String] Base64 encoded data
  def encode_data(data)
    Base64.encode64(data).strip
  end
end
