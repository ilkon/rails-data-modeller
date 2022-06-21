# frozen_string_literal: true

class CreateUserPasswords < ActiveRecord::Migration[6.0]
  def change
    table_name = 'user_passwords'

    create_table table_name do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :encrypted_password
      t.string :reset_token
      t.datetime :reset_sent_at
      t.datetime :changed_at

      t.timestamps
    end

    add_index table_name, :user_id, unique: true, name: "#{table_name}_user_id"
    add_index table_name, :reset_token, unique: true, name: "#{table_name}_reset_token"
  end
end
