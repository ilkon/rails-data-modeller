# frozen_string_literal: true

class CreateUserEmails < ActiveRecord::Migration[6.0]
  def change
    table_name = 'user_emails'

    create_table table_name do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :email, null: false
      t.string :confirm_token
      t.datetime :confirm_sent_at
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index table_name, :user_id, name: "#{table_name}_user_id"
    add_index table_name, :email, unique: true, name: "#{table_name}_email"
    add_index table_name, :confirm_token, unique: true, name: "#{table_name}_confirm_token"
  end
end
