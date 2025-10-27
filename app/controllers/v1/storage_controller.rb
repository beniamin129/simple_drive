module V1
  class StorageController < ApplicationController
    # GET /v1/storage/backend
    def backend
      backend_name = Rails.application.config.storage_backend

      render_success({
        backend: backend_name,
        config: Rails.application.config.storage_config
      })
    end
  end
end
