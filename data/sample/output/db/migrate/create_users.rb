# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    table_name = 'users'

    create_table table_name do |t|
      t.string :name, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
