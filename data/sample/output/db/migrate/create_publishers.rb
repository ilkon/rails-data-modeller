# frozen_string_literal: true

class CreatePublishers < ActiveRecord::Migration[6.0]
  def change
    table_name = 'publishers'

    create_table table_name do |t|
      t.string :name, null: false
      t.integer :count_of_vacancies, default: 0

      t.timestamps
    end

    add_index table_name, :name, unique: true, name: "#{table_name}_name"
  end
end
