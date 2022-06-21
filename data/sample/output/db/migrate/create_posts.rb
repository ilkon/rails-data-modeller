# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[6.0]
  def change
    table_name = 'posts'

    create_table table_name, id: :bigserial do |t|
      t.references :publisher, type: :uuid, null: false, index: false
      t.string :publisher_key, null: false
      t.datetime :published_at, null: false
      t.string :author
      t.text :text
      t.boolean :vacancy, default: false
      t.datetime :last_fetched_at, null: false
      t.datetime :last_parsed_at
      t.date :date, null: false

      t.timestamps
    end
  end
end
