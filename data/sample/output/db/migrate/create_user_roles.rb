# frozen_string_literal: true

class CreateUserRoles < ActiveRecord::Migration[6.0]
  def change
    table_name = 'user_roles'

    create_table table_name do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.boolean :admin, default: false

      t.timestamps
    end

    add_index table_name, :user_id, unique: true, name: "#{table_name}_user_id"
    add_index table_name, :admin, name: "#{table_name}_admin"
  end
end
