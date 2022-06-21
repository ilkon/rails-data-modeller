# frozen_string_literal: true

class CreateUserSocialProfiles < ActiveRecord::Migration[6.0]
  def change
    table_name = 'user_social_profiles'

    create_table table_name do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.integer :provider_id, null: false
      t.string :uid, null: false

      t.timestamps
    end

    add_index table_name, :user_id, name: "#{table_name}_user_id"
    add_index table_name, %i[provider_id uid], unique: true, name: "#{table_name}_provider_id_uid"
    add_index table_name, :provider_id, name: "#{table_name}_provider_id"
  end
end
