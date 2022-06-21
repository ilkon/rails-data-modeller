# frozen_string_literal: true

class CreateUserAddresses < ActiveRecord::Migration[6.0]
  def change
    table_name = 'user_addresses'

    create_table table_name do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :address_line, null: false
      t.string :address_line2
      t.string :city, null: false
      t.string :postal_code, null: false
      t.string :country, null: false
      t.string :phone, null: false

      t.timestamps
    end

    add_index table_name, :user_id, unique: true, name: "#{table_name}_user_id"
    add_index table_name, :phone, name: "#{table_name}_phone"
  end
end
