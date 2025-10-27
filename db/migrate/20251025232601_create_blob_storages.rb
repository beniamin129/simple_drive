class CreateBlobStorages < ActiveRecord::Migration[8.1]
  def change
    create_table :blob_storages, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.text :data, null: false

      t.timestamps
    end
  end
end
