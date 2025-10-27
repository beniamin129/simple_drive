require "net/ftp"
require "tempfile"
require "stringio"

# FTP Storage Adapter using net-ftp gem
# Implements FTP file storage for blob data
class FtpStorageAdapter < StorageBackend
  def initialize(config = {})
    # Support both symbol and string keys
    config_sym = config.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }

    @host = config_sym[:host] || ENV["FTP_HOST"]
    @username = config_sym[:username] || ENV["FTP_USERNAME"]
    @password = config_sym[:password] || ENV["FTP_PASSWORD"]
    @port = config_sym[:port] || ENV["FTP_PORT"] || 21
    @remote_path = config_sym[:remote_path] || ENV["FTP_REMOTE_PATH"] || "/blobs"
    @passive = config_sym[:passive] != false && ENV["FTP_PASSIVE"] != "false"

    if @host.nil? || @username.nil? || @password.nil?
      raise ArgumentError, "FTP configuration missing. Required: FTP_HOST, FTP_USERNAME, FTP_PASSWORD"
    end

    # Ensure remote path starts with /
    @remote_path = "/#{@remote_path}" unless @remote_path.start_with?("/")
  end

  def store(id, data)
    return false unless valid_base64?(data)

    binary_data = decode_data(data)
    remote_file_path = "#{@remote_path}/#{id}"

    # Retry logic for reliability
    max_retries = 3
    retry_count = 0

    begin
      with_ftp_connection do |ftp|
        # Ensure remote directory exists
        ensure_remote_directory(ftp, @remote_path)

        # Upload file using temp file (more reliable)
        Tempfile.open("blob_#{id}") do |temp_file|
          temp_file.binmode
          temp_file.write(binary_data)
          temp_file.rewind
          ftp.putbinaryfile(temp_file, remote_file_path)
        end

        true
      end
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => e
      retry_count += 1
      Rails.logger.warn "FTP store timeout/connection error (attempt #{retry_count}/#{max_retries}): #{e.message}"

      if retry_count < max_retries
        sleep(1)  # Wait 1 second before retry
        retry
      else
        Rails.logger.error "FTP store failed after #{max_retries} attempts: #{e.message}"
        false
      end
    rescue => e
      Rails.logger.error "FTP store error: #{e.message}"
      false
    end
  end

  def retrieve(id)
    remote_file_path = "#{@remote_path}/#{id}"

    # Retry logic for reliability
    max_retries = 3
    retry_count = 0

    begin
      with_ftp_connection do |ftp|
        # Download file directly to string instead of temp file
        data = ftp.getbinaryfile(remote_file_path, nil)  # nil = return as string

        # Encode as Base64
        encode_data(data)
      end
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => e
      retry_count += 1
      Rails.logger.warn "FTP retrieve timeout/connection error (attempt #{retry_count}/#{max_retries}): #{e.message}"

      if retry_count < max_retries
        sleep(1)  # Wait 1 second before retry
        retry
      else
        Rails.logger.error "FTP retrieve failed after #{max_retries} attempts: #{e.message}"
        nil
      end
    rescue Net::FTPPermError, Net::FTPReplyError => e
      Rails.logger.error "FTP retrieve error: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "FTP retrieve error: #{e.message}"
      nil
    end
  end

  def delete(id)
    remote_file_path = "#{@remote_path}/#{id}"

    # Retry logic for reliability
    max_retries = 3
    retry_count = 0

    begin
      with_ftp_connection do |ftp|
        # Check if file exists before attempting to delete
        return false unless file_exists?(ftp, remote_file_path)

        # Delete file from FTP server
        ftp.delete(remote_file_path)
        true
      end
    rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => e
      retry_count += 1
      Rails.logger.warn "FTP delete timeout/connection error (attempt #{retry_count}/#{max_retries}): #{e.message}"

      if retry_count < max_retries
        sleep(1)  # Wait 1 second before retry
        retry
      else
        Rails.logger.error "FTP delete failed after #{max_retries} attempts: #{e.message}"
        false
      end
    rescue Net::FTPPermError => e
      # File might not exist or permission error
      Rails.logger.warn "FTP delete permission error: #{e.message}"
      false
    rescue => e
      Rails.logger.error "FTP delete error: #{e.message}"
      false
    end
  end

  def exists?(id)
    remote_file_path = "#{@remote_path}/#{id}"

    begin
      with_ftp_connection do |ftp|
        file_exists?(ftp, remote_file_path)
      end
    rescue => e
      Rails.logger.error "FTP exists? error: #{e.message}"
      false
    end
  end

  def size(id)
    remote_file_path = "#{@remote_path}/#{id}"

    begin
      with_ftp_connection do |ftp|
        # Get file size using SIZE command
        ftp.size(remote_file_path)
      end
    rescue => e
      Rails.logger.error "FTP size error: #{e.message}"
      nil
    end
  end

  private

  def with_ftp_connection
    ftp = Net::FTP.new
    ftp.connect(@host, @port)
    ftp.login(@username, @password)
    ftp.passive = @passive
    ftp.read_timeout = 30  # 30 seconds timeout
    ftp.open_timeout = 10  # 10 seconds connection timeout

    yield(ftp)
  rescue => e
    Rails.logger.error "FTP connection error: #{e.message}"
    raise e
  ensure
    ftp&.close
  end

  def ensure_remote_directory(ftp, path)
    # Split path into components
    path_parts = path.split("/").reject(&:empty?)
    current_path = ""

    path_parts.each do |part|
      current_path = "#{current_path}/#{part}"

      begin
        # Try to change to directory
        ftp.chdir(current_path)
      rescue Net::FTPPermError
        # Directory doesn't exist, create it
        begin
          ftp.mkdir(current_path)
          Rails.logger.info "Created FTP directory: #{current_path}"
        rescue Net::FTPPermError => e
          Rails.logger.error "Failed to create FTP directory #{current_path}: #{e.message}"
          raise e
        end
      end
    end
  end

  def file_exists?(ftp, remote_file_path)
    # Try to get file size - if it succeeds, file exists
    ftp.size(remote_file_path)
    true
  rescue Net::FTPPermError, Net::FTPReplyError
    false
  end

  def valid_base64?(data)
    return false if data.nil? || data.empty?

    begin
      Base64.decode64(data)
      true
    rescue ArgumentError
      false
    end
  end

  def decode_data(data)
    Base64.decode64(data)
  end

  def encode_data(data)
    Base64.encode64(data).strip
  end
end
