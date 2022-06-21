# frozen_string_literal: true

class CreateEmployers < ActiveRecord::Migration[6.0]
  def change
    table_name = 'employers'

    create_table table_name do |t|
      t.string :name, null: false
      t.string :url
      t.integer :vacancies_count, default: 0

      t.timestamps
    end

    add_index table_name, :name, unique: true, name: "#{table_name}_name"
  end
end
