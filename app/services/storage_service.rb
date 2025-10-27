class StorageService
  require_relative "storage_adapters/storage_backend"
  require_relative "storage_adapters/s3_storage_adapter"
  require_relative "storage_adapters/database_storage_adapter"
  require_relative "storage_adapters/local_file_storage_adapter"
  require_relative "storage_adapters/ftp_storage_adapter"

  STORAGE_TYPES = {
    "s3" => S3StorageAdapter,
    "database" => DatabaseStorageAdapter,
    "local" => LocalFileStorageAdapter,
    "ftp" => FtpStorageAdapter
  }.freeze

  def initialize(storage_type = nil, config = {})
    @storage_type = storage_type || Rails.application.config.storage_backend || "local"

    if config.empty?
      @config = load_config_from_rails
    else
      @config = config
    end

    @adapter = create_adapter
  end

  def store(id, data)
    @adapter.store(id, data)
  end

  def retrieve(id)
    @adapter.retrieve(id)
  end

  def delete(id)
    @adapter.delete(id)
  end

  def exists?(id)
    @adapter.exists?(id)
  end

  def size(id)
    @adapter.size(id)
  end

  def storage_type
    @storage_type
  end

  def backend_name
    @storage_type
  end

  private

  def create_adapter
    adapter_class = STORAGE_TYPES[@storage_type]
    raise ArgumentError, "Unknown storage type: #{@storage_type}" unless adapter_class

    adapter_class.new(@config)
  end

  def load_config_from_rails
    begin
      rails_config = Rails.application.config.storage_config || {}

      config_hash = {}
      if rails_config.is_a?(Hash)
        rails_config.each do |key, value|
          config_hash[key.to_sym] = value
        end
      end

      config_hash
    rescue => e
      Rails.logger.error "Failed to load config from Rails: #{e.message}" if defined?(Rails)
      {}
    end
  end
end
