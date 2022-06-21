# frozen_string_literal: true

class CreateSkills < ActiveRecord::Migration[6.0]
  def change
    table_name = 'skills'

    create_table table_name do |t|
      t.string :name, null: false
      t.jsonb :synonyms, default: []

      t.timestamps
    end

    add_index table_name, :name, unique: true, name: "#{table_name}_name"
  end
end
