# frozen_string_literal: true

class CreateVacancies < ActiveRecord::Migration[6.0]
  def change
    table_name = 'vacancies'

    create_table table_name, id: :bigserial do |t|
      t.references :publisher, null: false, index: false
      t.references :post, null: false, index: false
      t.datetime :published_at, null: false
      t.references :employer, index: false
      t.integer :remoteness
      t.integer :involvement
      t.jsonb :skill_ids, default: []
      t.jsonb :urls, default: []
      t.jsonb :emails, default: []
      t.text :text, null: false
      t.date :date, null: false
      t.decimal :geo_latitude, precision: 10, scale: 7
      t.decimal :geo_longitude, precision: 10, scale: 7

      t.timestamps
    end
  end
end
