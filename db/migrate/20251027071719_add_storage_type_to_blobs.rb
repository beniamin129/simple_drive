class AddStorageTypeToBlobs < ActiveRecord::Migration[8.1]
  def change
    add_column :blobs, :storage_type, :string
  end
end
