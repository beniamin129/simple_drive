module V1
  class BlobsController < ApplicationController
    before_action :set_blob_service

    # GET /v1/blobs
    def index
      page = params[:page].to_i
      page = 1 if page < 1
      per_page = params[:per_page].to_i
      per_page = 10 if per_page < 1 || per_page > 100  # Default 10, max 100

      total_count = Blob.count
      offset = (page - 1) * per_page

      blobs = Blob.order(created_at: :desc)
                  .limit(per_page)
                  .offset(offset)

      total_pages = (total_count.to_f / per_page).ceil

      render json: {
        data: blobs.map { |blob|
          {
            id: blob.id,
            storage: blob.storage_type || "unknown",
            size: blob.size.to_s,
            created_at: blob.created_at.utc.iso8601
          }
        },
        pagination: {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: total_pages,
          has_next: page < total_pages,
          has_prev: page > 1
        }
      }
    end

    # POST /v1/blobs
    def create
      # Validate required parameters
      unless params[:id].present? && params[:data].present?
        return render_error("Missing required parameters: id and data")
      end

      # Determine which storage backend to use
      storage_type = params[:storage_backend].presence || Rails.application.config.storage_backend

      # Get configuration for the specified storage backend
      all_configs = Rails.application.config.all_storage_configs || {}
      backend_config = all_configs[storage_type] || {}

      # Handle special configurations for S3 and FTP
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

      # Create a new BlobService instance with the specified storage backend
      blob_service = BlobService.new(StorageService.new(storage_type, backend_config))

      # Create blob
      result = blob_service.create_blob(params[:id], params[:data])

      if result[:success]
        blob = result[:blob]
        render_success({
          id: blob.id,
          data: params[:data], # Return the original Base64 data
          size: blob.size.to_s,
          created_at: blob.created_at.utc.iso8601
        }, :created)
      else
        render_error(result[:error], :unprocessable_entity)
      end
    end

    # GET /v1/blobs/:id
    def show
      result = @blob_service.get_blob(params[:id])

      if result[:success]
        blob = result[:blob]
        render_success({
          id: blob.id,
          data: blob.data, # Base64 encoded data
          size: blob.size.to_s,
          created_at: blob.created_at.utc.iso8601
        })
      else
        render_error(result[:error], :not_found)
      end
    end

    # DELETE /v1/blobs/:id
    def destroy
      result = @blob_service.delete_blob(params[:id])

      if result[:success]
        head :no_content
      else
        render_error(result[:error], :not_found)
      end
    end

    private

    def set_blob_service
      @blob_service = BlobService.new
    end
  end
end
