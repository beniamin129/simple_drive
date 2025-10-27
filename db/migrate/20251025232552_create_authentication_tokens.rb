class CreateAuthenticationTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :authentication_tokens do |t|
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :authentication_tokens, :token, unique: true
  end
end
