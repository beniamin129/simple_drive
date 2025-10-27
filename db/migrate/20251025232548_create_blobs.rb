class CreateBlobs < ActiveRecord::Migration[8.1]
  def change
    create_table :blobs, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.integer :size, null: false

      t.timestamps
    end
  end
end
