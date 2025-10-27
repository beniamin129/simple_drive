# Storage Backend Configuration Initializer
require "yaml"
require "erb"

# Load storage backend configuration with ERB processing
yaml_content = File.read(Rails.root.join("config", "storage_backends.yml"))
erb_content = ERB.new(yaml_content).result
storage_config = YAML.load(erb_content, aliases: true)
env_config = storage_config[Rails.env] || storage_config["default"]

# Set the default storage backend
Rails.application.config.storage_backend = env_config["backend"]

# Store all backend configurations for use by storage adapters
Rails.application.config.all_storage_configs = env_config

# Store the specific backend configuration for use by storage adapters
backend_name = env_config["backend"]
backend_config = env_config[backend_name] || {}

# For S3, check environment variables for credentials
if backend_name == "s3"
  region = ENV["S3_REGION"] || backend_config["region"] || "us-east-1"

  # Use regional endpoint if no specific endpoint is provided
  default_endpoint = if ENV["S3_ENDPOINT"]
    ENV["S3_ENDPOINT"]
  elsif backend_config["endpoint"]
    backend_config["endpoint"]
  else
    "https://s3.#{region}.amazonaws.com"
  end

  backend_config = {
    "endpoint" => default_endpoint,
    "bucket" => ENV["S3_BUCKET"] || backend_config["bucket"],
    "access_key" => ENV["S3_ACCESS_KEY"] || backend_config["access_key"],
    "secret_key" => ENV["S3_SECRET_KEY"] || backend_config["secret_key"],
    "region" => region
  }
end

# For FTP, check environment variables for credentials
if backend_name == "ftp"
  backend_config = {
    "host" => ENV["FTP_HOST"] || backend_config["host"],
    "username" => ENV["FTP_USERNAME"] || backend_config["username"],
    "password" => ENV["FTP_PASSWORD"] || backend_config["password"],
    "port" => ENV["FTP_PORT"] || backend_config["port"] || 21,
    "remote_path" => ENV["FTP_REMOTE_PATH"] || backend_config["remote_path"] || "/blobs",
    "passive" => ENV["FTP_PASSIVE"] != "false" && backend_config["passive"] != false
  }
end

Rails.application.config.storage_config = backend_config || {}
