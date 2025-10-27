require "httparty"
require "openssl"
require "time"

# S3 Compatible Storage Adapter using HTTP client only
# Implements S3 API without using any S3 libraries
class S3StorageAdapter < StorageBackend
  include HTTParty

  def initialize(config = {})
    # Support both symbol and string keys
    config_sym = config.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }

    @endpoint = config_sym[:endpoint] || ENV["S3_ENDPOINT"] || "https://s3.amazonaws.com"
    @bucket = config_sym[:bucket] || ENV["S3_BUCKET"]
    @access_key = config_sym[:access_key] || ENV["S3_ACCESS_KEY"]
    @secret_key = config_sym[:secret_key] || ENV["S3_SECRET_KEY"]
    @region = config_sym[:region] || ENV["S3_REGION"] || "us-east-1"

    if @bucket.nil? || @access_key.nil? || @secret_key.nil?
      raise ArgumentError, "S3 configuration missing. Required: S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY"
    end

    @base_uri = @endpoint
  end

  def store(id, data)
    return false unless valid_base64?(data)

    binary_data = decode_data(data)
    object_key = "blobs/#{id}"

    begin
      response = put_object(object_key, binary_data)
      response.success?
    rescue => e
      Rails.logger.error "S3 store error: #{e.message}"
      false
    end
  end

  def retrieve(id)
    object_key = "blobs/#{id}"

    begin
      response = get_object(object_key)
      return nil unless response.success?

      encode_data(response.body)
    rescue => e
      Rails.logger.error "S3 retrieve error: #{e.message}"
      nil
    end
  end

  def delete(id)
    object_key = "blobs/#{id}"

    begin
      response = delete_object(object_key)
      response.success?
    rescue => e
      Rails.logger.error "S3 delete error: #{e.message}"
      false
    end
  end

  def exists?(id)
    object_key = "blobs/#{id}"

    begin
      response = head_object(object_key)
      response.success?
    rescue => e
      Rails.logger.error "S3 exists? error: #{e.message}"
      false
    end
  end

  def size(id)
    object_key = "blobs/#{id}"

    begin
      response = head_object(object_key)
      return nil unless response.success?

      response.headers["content-length"].to_i
    rescue => e
      Rails.logger.error "S3 size error: #{e.message}"
      nil
    end
  end

  private

  def put_object(key, data)
    uri = "/#{@bucket}/#{key}"
    headers = build_headers("PUT", uri, data)

    self.class.put(uri, {
      body: data,
      headers: headers,
      base_uri: @base_uri
    })
  end

  def get_object(key)
    uri = "/#{@bucket}/#{key}"
    headers = build_headers("GET", uri)

    self.class.get(uri, {
      headers: headers,
      base_uri: @base_uri
    })
  end

  def delete_object(key)
    uri = "/#{@bucket}/#{key}"
    headers = build_headers("DELETE", uri)

    self.class.delete(uri, {
      headers: headers,
      base_uri: @base_uri
    })
  end

  def head_object(key)
    uri = "/#{@bucket}/#{key}"
    headers = build_headers("HEAD", uri)

    self.class.head(uri, {
      headers: headers,
      base_uri: @base_uri
    })
  end

  def build_headers(method, uri, body = nil)
    timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = timestamp[0, 8]

    headers = {
      "Host" => extract_host(@base_uri),
      "X-Amz-Date" => timestamp,
      "X-Amz-Content-Sha256" => body ? Digest::SHA256.hexdigest(body) : "UNSIGNED-PAYLOAD"
    }

    headers["Content-Type"] = "application/octet-stream" if body

    # Create canonical request
    canonical_request = build_canonical_request(method, uri, headers, body)

    # Create string to sign
    credential_scope = "#{date_stamp}/#{@region}/s3/aws4_request"
    string_to_sign = build_string_to_sign(timestamp, credential_scope, canonical_request)

    # Calculate signature
    signature = calculate_signature(string_to_sign, date_stamp)

    # Add authorization header
    headers["Authorization"] = "AWS4-HMAC-SHA256 Credential=#{@access_key}/#{credential_scope}, SignedHeaders=#{signed_headers(headers)}, Signature=#{signature}"

    headers
  end

  def build_canonical_request(method, uri, headers, body)
    canonical_uri = uri
    canonical_querystring = ""
    canonical_headers = headers.sort.map { |k, v| "#{k.downcase}:#{v.strip}\n" }.join
    signed_headers_list = signed_headers(headers)
    payload_hash = body ? Digest::SHA256.hexdigest(body) : "UNSIGNED-PAYLOAD"

    "#{method}\n#{canonical_uri}\n#{canonical_querystring}\n#{canonical_headers}\n#{signed_headers_list}\n#{payload_hash}"
  end

  def build_string_to_sign(timestamp, credential_scope, canonical_request)
    "AWS4-HMAC-SHA256\n#{timestamp}\n#{credential_scope}\n#{Digest::SHA256.hexdigest(canonical_request)}"
  end

  def calculate_signature(string_to_sign, date_stamp)
    k_date = OpenSSL::HMAC.digest("sha256", "AWS4#{@secret_key}", date_stamp)
    k_region = OpenSSL::HMAC.digest("sha256", k_date, @region)
    k_service = OpenSSL::HMAC.digest("sha256", k_region, "s3")
    k_signing = OpenSSL::HMAC.digest("sha256", k_service, "aws4_request")

    OpenSSL::HMAC.hexdigest("sha256", k_signing, string_to_sign)
  end

  def signed_headers(headers)
    headers.keys.map(&:downcase).sort.join(";")
  end

  def extract_host(uri)
    uri.gsub(/^https?:\/\//, "").split("/").first
  end
end
